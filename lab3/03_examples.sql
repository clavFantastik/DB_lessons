SELECT '=== Example 1: Valid booking ===' AS example;

CALL add_booking_with_validation(4, 1, '2026-06-15', '2026-06-20');

SELECT '=== Example 2: Check user activity ===' AS example;

SELECT * FROM check_user_booking_activity(4);

SELECT '=== Example 3: Update property rating ===' AS example;

CALL update_property_rating(1);

SELECT '=== Example 4: Overlapping dates (should fail) ===' AS example;

DO $$
BEGIN
    CALL add_booking_with_validation(4, 1, '2026-06-16', '2026-06-18');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 5: Invalid dates (checkout before checkin) ===' AS example;

DO $$
BEGIN
    CALL add_booking_with_validation(4, 1, '2026-06-20', '2026-06-15');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 6: Non-existent property ===' AS example;

DO $$
BEGIN
    CALL add_booking_with_validation(4, 9999, '2026-07-01', '2026-07-05');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 7: Unverified user ===' AS example;

DO $$
BEGIN
    CALL add_booking_with_validation(5, 2, '2026-07-01', '2026-07-05');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 8: Direct INSERT with trigger validation ===' AS example;

DO $$
BEGIN
    INSERT INTO bookings (guest_id, property_id, check_in_date, check_out_date, total_price, status)
    VALUES (6, 1, '2026-06-16', '2026-06-18', 200.00, 'confirmed');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Trigger Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 9: Invalid rating ===' AS example;

DO $$
BEGIN
    INSERT INTO reviews (booking_id, rating, comment)
    VALUES (1, 6, 'This should fail');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 10: Valid review ===' AS example;

DO $$
BEGIN
    INSERT INTO reviews (booking_id, rating, comment)
    VALUES (8, 5, 'Excellent stay!');
    RAISE NOTICE 'Review added successfully';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 11: Check audit logs ===' AS example;

SELECT
    audit_id,
    booking_id,
    old_status,
    new_status,
    changed_at,
    changed_by
FROM booking_audit
ORDER BY changed_at DESC
LIMIT 10;

SELECT '=== Example 12: Check property stats ===' AS example;

SELECT
    ps.property_id,
    p.title,
    ps.total_reviews,
    ps.avg_rating,
    ps.last_review_at
FROM property_stats ps
JOIN properties p ON ps.property_id = p.property_id
ORDER BY ps.total_reviews DESC;

SELECT '=== Example 13: Update booking status with audit ===' AS example;

DO $$
BEGIN
    UPDATE bookings
    SET status = 'confirmed'
    WHERE booking_id = (SELECT booking_id FROM bookings WHERE status = 'pending' LIMIT 1);
    RAISE NOTICE 'Booking status updated';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error: % (SQLSTATE: %)', SQLERRM, SQLSTATE;
END $$;

SELECT '=== Example 14: Check review audit log ===' AS example;

SELECT
    log_id,
    review_id,
    booking_id,
    rating,
    action,
    created_at
FROM review_audit_log
ORDER BY created_at DESC
LIMIT 5;

SELECT '=== Example 15: Multi-user activity report ===' AS example;

SELECT
    u.user_id,
    u.first_name,
    u.last_name,
    COALESCE(uba.total_bookings, 0) AS bookings,
    COALESCE(uba.completed_bookings, 0) AS completed,
    COALESCE(uba.total_spent, 0) AS spent
FROM users u
LEFT JOIN LATERAL check_user_booking_activity(u.user_id) uba ON true
WHERE u.role IN ('guest', 'both')
ORDER BY uba.total_spent DESC NULLS LAST;
