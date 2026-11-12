
CREATE OR REFRESH STREAMING TABLE bronze_course_enrollments_v2

AS

SELECT
    *,
    _metadata.file_name AS source_file,
    current_timestamp() AS loaded_at

FROM STREAM read_files(
    '/Volumes/online_learning_sdp/default/online_volume/',
    format => 'csv',
    header => true,
    inferColumnTypes => false
);


# BRONZE

CREATE OR REFRESH STREAMING TABLE bronze_course_enrollments_v2

AS

SELECT
    *,
    _metadata.file_name AS source_file,
    current_timestamp() AS loaded_at

FROM STREAM read_files(
    '/Volumes/online_learning_sdp/default/online_volume/',
    format => 'csv',
    header => true,
    inferColumnTypes => false
);


# SLIVER CLEAN 

CREATE OR REFRESH MATERIALIZED VIEW silver_enrollments_clean (

    CONSTRAINT valid_progress
    EXPECT (
        progress_pct IS NOT NULL
        AND progress_pct BETWEEN 0 AND 100
    )
    ON VIOLATION DROP ROW,

    CONSTRAINT valid_price
    EXPECT (
        price_paid IS NOT NULL
        AND price_paid >= 0
    )
    ON VIOLATION DROP ROW

)

AS

WITH cleaned AS (

    SELECT DISTINCT

        enrollment_id,
        course_name,
        enrollment_date,

        progress_pct,
        discount_amount,

        -- Clean learner email
        NULLIF(LOWER(TRIM(learner_email)), '')
            AS learner_email,

        -- Clean category
        COALESCE(
            NULLIF(INITCAP(TRIM(category)), ''),
            'Unknown'
        ) AS category,

        -- Clean course level
        COALESCE(
            NULLIF(INITCAP(TRIM(course_level)), ''),
            'Unknown'
        ) AS course_level,

        -- Calculate final price
        COALESCE(
            price_paid,
            list_price - COALESCE(discount_amount, 0)
        ) AS price_paid,

        -- Clean learner city
        COALESCE(
            NULLIF(INITCAP(TRIM(learner_city)), ''),
            'Unknown'
        ) AS learner_city,

        -- Clean enrollment channel
        COALESCE(
            NULLIF(INITCAP(TRIM(enrollment_channel)), ''),
            'Unknown'
        ) AS enrollment_channel,

        source_file,
        loaded_at

    FROM bronze_course_enrollments_v2

)

SELECT *,

    CASE
        WHEN progress_pct = 100 THEN 'Completed'
        WHEN progress_pct > 0 THEN 'In Progress'
        ELSE 'Not Started'
    END AS learner_status

FROM cleaned;



# SILVER REJECTED

CREATE OR REFRESH MATERIALIZED VIEW silver_enrollments_rejected

AS

WITH evaluated AS (

    SELECT *,

        COALESCE(
            price_paid,
            list_price - COALESCE(discount_amount, 0)
        ) AS evaluated_price_paid

    FROM bronze_course_enrollments_v2

)

SELECT *,

    CONCAT_WS(
        '; ',

        CASE
            WHEN progress_pct IS NULL
                 OR progress_pct NOT BETWEEN 0 AND 100
            THEN 'Progress is outside 0 to 100'
        END,

        CASE
            WHEN evaluated_price_paid IS NULL
            THEN 'Price paid is missing'

            WHEN evaluated_price_paid < 0
            THEN 'Price paid is negative'
        END

    ) AS reject_reason

FROM evaluated

WHERE
    progress_pct IS NULL
    OR progress_pct NOT BETWEEN 0 AND 100
    OR evaluated_price_paid IS NULL
    OR evaluated_price_paid < 0;




# GOLD_LAYER

-- 1. MONTHLY ENROLLMENTS

CREATE OR REFRESH MATERIALIZED VIEW gold_monthly_enrollments

AS

SELECT
    DATE_TRUNC('MONTH', TRY_CAST(enrollment_date AS DATE)) AS enrollment_month,

    COUNT(*) AS enrollments,

    COUNT(DISTINCT learner_email) AS unique_learners,

    SUM(TRY_CAST(price_paid AS DECIMAL(12,2))) AS revenue,

    SUM(TRY_CAST(discount_amount AS DECIMAL(12,2))) AS total_discount,

    SUM(
        CASE WHEN learner_status = 'Completed'
        THEN 1 ELSE 0 END
    ) AS completions

FROM online_learning_sdp.default.silver_enrollments_clean

GROUP BY 1;


-- =====================================================
-- 2. CATEGORY SUMMARY

CREATE OR REFRESH MATERIALIZED VIEW gold_category_summary

AS

SELECT
    category,

    COUNT(*) AS enrollments,

    SUM(TRY_CAST(price_paid AS DECIMAL(12,2))) AS revenue,

    SUM(
        CASE WHEN learner_status = 'Completed'
        THEN 1 ELSE 0 END
    ) AS completed,

    SUM(
        CASE WHEN learner_status = 'In Progress'
        THEN 1 ELSE 0 END
    ) AS in_progress,

    SUM(
        CASE WHEN learner_status = 'Not Started'
        THEN 1 ELSE 0 END
    ) AS not_started,

    ROUND(
        SUM(
            CASE WHEN learner_status = 'Completed'
            THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*),
        2
    ) AS completion_rate_pct,

    ROUND(AVG(TRY_CAST(progress_pct AS DOUBLE)), 2) AS avg_progress_pct

FROM online_learning_sdp.default.silver_enrollments_clean

GROUP BY category;


-- =====================================================
-- 3. COURSE SUMMARY

CREATE OR REFRESH MATERIALIZED VIEW gold_course_summary

AS

SELECT
    category,

    course_name,

    course_level,

    COUNT(*) AS enrollments,

    SUM(TRY_CAST(price_paid AS DECIMAL(12,2))) AS revenue,

    ROUND(
        SUM(
            CASE WHEN learner_status = 'Completed'
            THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*),
        2
    ) AS completion_rate_pct

FROM online_learning_sdp.default.silver_enrollments_clean

GROUP BY
    category,
    course_name,
    course_level;


-- =====================================================
-- 4. CHANNEL SUMMARY

CREATE OR REFRESH MATERIALIZED VIEW gold_channel_summary

AS

SELECT
    enrollment_channel,

    COUNT(*) AS enrollments,

    SUM(TRY_CAST(price_paid AS DECIMAL(12,2))) AS revenue,

    ROUND(
        SUM(
            CASE WHEN learner_status = 'Completed'
            THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*),
        2
    ) AS completion_rate_pct

FROM online_learning_sdp.default.silver_enrollments_clean

GROUP BY enrollment_channel;


-- =====================================================
-- STEP 06: DATA QUALITY AND RECONCILIATION
-- =====================================================


-- 5. DATA QUALITY SUMMARY

CREATE OR REFRESH MATERIALIZED VIEW gold_data_quality

AS

SELECT

    COUNT(*) AS bronze_rows,

    COUNT(*) - COUNT(DISTINCT enrollment_id)
        AS duplicate_rows,

    SUM(
        CASE
            WHEN TRY_CAST(progress_pct AS INT) < 0
              OR TRY_CAST(progress_pct AS INT) > 100
              OR TRY_CAST(progress_pct AS INT) IS NULL
            THEN 1 ELSE 0
        END
    ) AS invalid_progress_rows,

    SUM(
        CASE
            WHEN TRY_CAST(price_paid AS DECIMAL(12,2)) < 0
            THEN 1 ELSE 0
        END
    ) AS negative_price_rows,

    SUM(
        CASE
            WHEN category IS NULL OR TRIM(category) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_category_rows,

    SUM(
        CASE
            WHEN learner_city IS NULL OR TRIM(learner_city) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_city_rows,

    SUM(
        CASE
            WHEN price_paid IS NULL
                 OR TRIM(CAST(price_paid AS STRING)) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_price_rows,

    COUNT(DISTINCT learner_email)
        AS learners_before_email_fix,

    COUNT(DISTINCT LOWER(TRIM(learner_email)))
        AS learners_after_email_fix,

    (
        SELECT COUNT(*)
        FROM online_learning_sdp.default.silver_enrollments_clean
    ) AS clean_rows,

    (
        SELECT COUNT(*)
        FROM online_learning_sdp.default.silver_enrollments_rejected
    ) AS rejected_rows,

    CASE
        WHEN COUNT(*) =
            (
                SELECT COUNT(*)
                FROM online_learning_sdp.default.silver_enrollments_clean
            )
            +
            (
                SELECT COUNT(*)
                FROM online_learning_sdp.default.silver_enrollments_rejected
            )
            +
            (
                COUNT(*) - COUNT(DISTINCT enrollment_id)
            )
        THEN 'Yes'
        ELSE 'No'
    END AS reconciliation_passed

FROM online_learning_sdp.default.bronze_course_enrollments_v2;
