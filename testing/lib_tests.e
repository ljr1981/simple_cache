note
	description: "Test set for simple_cache"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	LIB_TESTS

inherit
	TEST_SET_BASE

feature {NONE} -- Fixtures

	fixtures: CACHE_FIXTURES
		once
			create Result
		end

feature -- Basic Tests

	test_make_default
			-- Test default cache creation.
		do
			assert_integers_equal ("max_size", 10, fixtures.empty_cache.max_size)
			assert_true ("initially_empty", fixtures.empty_cache.is_empty)
			assert_integers_equal ("no_ttl", 0, fixtures.empty_cache.default_ttl)
		end

	test_make_with_ttl
			-- Test cache creation with TTL.
		do
			assert_integers_equal ("max_size", 10, fixtures.cache_with_ttl.max_size)
			assert_integers_equal ("ttl_set", 3600, fixtures.cache_with_ttl.default_ttl)
		end

feature -- Put/Get Tests

	test_put_and_get
			-- Test basic put and get.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			cache := fixtures.empty_cache
			cache.put ("key1", "value1")
			assert_true ("has_key", cache.has ("key1"))
			assert_attached ("value_present", cache.get ("key1"))
		end

	test_get_missing_key
			-- Test get on missing key returns Void.
		do
			assert_void ("missing", fixtures.empty_cache.get ("nonexistent"))
			assert_false ("not_has", fixtures.empty_cache.has ("nonexistent"))
		end

	test_put_overwrites
			-- Test that put overwrites existing value.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			cache := fixtures.empty_cache
			cache.put ("key1", "value1")
			cache.put ("key1", "value2")
			assert_integers_equal ("count_unchanged", 1, cache.count)
		end

	test_put_integer_values
			-- Test cache with integer values.
		local
			cache: SIMPLE_CACHE [INTEGER]
		do
			cache := fixtures.empty_integer_cache
			cache.put ("count", 42)
			cache.put ("total", 100)
			assert_attached ("has_count", cache.get ("count"))
			assert_attached ("has_total", cache.get ("total"))
		end

feature -- LRU Eviction Tests

	test_lru_eviction
			-- Test LRU eviction when capacity reached.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			cache := fixtures.empty_small_cache
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			cache.put ("d", "4")
			assert_false ("a_evicted", cache.has ("a"))
			assert_true ("b_present", cache.has ("b"))
			assert_true ("c_present", cache.has ("c"))
			assert_true ("d_present", cache.has ("d"))
		end

	test_lru_access_updates_order
			-- Test that access updates LRU order.
		local
			cache: SIMPLE_CACHE [STRING]
			l_temp: detachable STRING
		do
			cache := fixtures.empty_small_cache
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			l_temp := cache.get ("a")
			cache.put ("d", "4")
			assert_true ("a_present", cache.has ("a"))
			assert_true ("some_evicted", not cache.has ("b") or not cache.has ("c"))
			assert_true ("d_present", cache.has ("d"))
		end

feature -- Removal Tests

	test_remove
			-- Test removing an entry.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			cache := fixtures.empty_cache
			cache.put ("key1", "value1")
			cache.put ("key2", "value2")
			cache.remove ("key1")
			assert_false ("removed", cache.has ("key1"))
			assert_true ("other_remains", cache.has ("key2"))
			assert_integers_equal ("count_updated", 1, cache.count)
		end

	test_clear
			-- Test clearing all entries.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			cache := fixtures.empty_cache
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			cache.clear
			assert_true ("emptied", cache.is_empty)
			assert_integers_equal ("count_zero", 0, cache.count)
		end

feature -- Statistics Tests

	test_hit_miss_tracking
			-- Test hit/miss statistics.
		do
			assert_integers_equal ("hits", 2, fixtures.stats_established_cache.hits)
			assert_integers_equal ("misses", 1, fixtures.stats_established_cache.misses)
		end

	test_hit_rate
			-- Test hit rate calculation.
		local
			cache: SIMPLE_CACHE [STRING]
			l_temp: detachable STRING
		do
			cache := fixtures.empty_cache
			cache.put ("key1", "value1")
			l_temp := cache.get ("key1")
			l_temp := cache.get ("key1")
			l_temp := cache.get ("key1")
			l_temp := cache.get ("missing")
			assert_reals_equal ("hit_rate", 0.75, cache.hit_rate, 0.001)
		end

	test_eviction_count
			-- Test eviction tracking.
		do
			assert_integers_equal ("eviction_count", 2, fixtures.exhausted_cache.evictions)
		end

	test_reset_statistics
			-- Test resetting statistics.
		local
			cache: SIMPLE_CACHE [STRING]
			l_temp: detachable STRING
		do
			cache := fixtures.stats_established_cache
			cache.reset_statistics
			assert_integers_equal ("hits_reset", 0, cache.hits)
			assert_integers_equal ("misses_reset", 0, cache.misses)
			assert_integers_equal ("evictions_reset", 0, cache.evictions)
		end

feature -- Configuration Tests

	test_set_max_size_smaller
			-- Test shrinking cache size.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			cache := fixtures.empty_cache
			cache.put ("a", "1")
			cache.put ("b", "2")
			cache.put ("c", "3")
			cache.put ("d", "4")
			cache.put ("e", "5")
			cache.set_max_size (2)
			assert_integers_equal ("new_size", 2, cache.max_size)
			assert_integers_equal ("count_reduced", 2, cache.count)
		end

feature -- Edge Cases

	test_empty_cache_hit_rate
			-- Test hit rate when cache unused.
		do
			assert_reals_equal ("zero_rate", 0.0, fixtures.empty_cache.hit_rate, 0.001)
		end

	test_is_full
			-- Test is_full predicate.
		local
			cache: SIMPLE_CACHE [STRING]
		do
			cache := fixtures.empty_small_cache
			assert_false ("not_full_initially", cache.is_full)
			cache.put ("a", "1")
			assert_false ("not_full_yet", cache.is_full)
			cache.put ("b", "2")
			assert_false ("not_full_yet_2", cache.is_full)
			cache.put ("c", "3")
			assert_true ("now_full", cache.is_full)
		end

feature -- Redis Client Tests

	test_redis_make
			-- Test Redis client creation.
		local
			redis: SIMPLE_REDIS
		do
			create redis.make ("localhost", 6379)
			assert_true ("host_set", redis.host.same_string ("localhost"))
			assert_integers_equal ("port_set", 6379, redis.port)
			assert_false ("not_connected", redis.is_connected)
		end

	test_redis_make_with_auth
			-- Test Redis client with authentication.
		local
			redis: SIMPLE_REDIS
		do
			create redis.make_with_auth ("localhost", 6379, "secret")
			assert_true ("host_set", redis.host.same_string ("localhost"))
			assert_attached ("password_set", redis.password)
		end

	test_redis_make_with_database
			-- Test Redis client with database selection.
		local
			redis: SIMPLE_REDIS
		do
			create redis.make_with_database ("localhost", 6379, 5)
			assert_integers_equal ("database_set", 5, redis.database)
		end

	test_redis_connect_offline
			-- Test Redis connect when server unavailable.
		local
			redis: SIMPLE_REDIS
			l_connected: BOOLEAN
		do
			create redis.make ("localhost", 59999)
			l_connected := redis.connect
			assert_false ("not_connected", l_connected)
			assert_true ("has_error", redis.has_error)
		end

feature -- Redis Cache Tests

	test_redis_cache_make
			-- Test Redis cache creation.
		local
			cache: SIMPLE_REDIS_CACHE
		do
			create cache.make ("localhost", 6379, 1000)
			assert_integers_equal ("max_size_set", 1000, cache.max_size)
			assert_integers_equal ("no_ttl", 0, cache.default_ttl)
			assert_false ("not_connected", cache.is_connected)
		end

	test_redis_cache_make_with_ttl
			-- Test Redis cache with TTL.
		local
			cache: SIMPLE_REDIS_CACHE
		do
			create cache.make_with_ttl ("localhost", 6379, 500, 3600)
			assert_integers_equal ("max_size_set", 500, cache.max_size)
			assert_integers_equal ("ttl_set", 3600, cache.default_ttl)
		end

	test_redis_cache_make_with_auth
			-- Test Redis cache with authentication.
		local
			cache: SIMPLE_REDIS_CACHE
		do
			create cache.make_with_auth ("localhost", 6379, 1000, "password")
			assert_integers_equal ("max_size_set", 1000, cache.max_size)
		end

	test_redis_cache_key_prefix
			-- Test key prefix functionality.
		local
			cache: SIMPLE_REDIS_CACHE
		do
			create cache.make ("localhost", 6379, 1000)
			assert_true ("empty_prefix", cache.key_prefix.is_empty)
			cache.set_key_prefix ("myapp:")
			assert_true ("prefix_set", cache.key_prefix.same_string ("myapp:"))
		end

	test_redis_cache_statistics
			-- Test Redis cache statistics tracking.
		local
			cache: SIMPLE_REDIS_CACHE
		do
			create cache.make ("localhost", 6379, 1000)
			assert_integers_equal ("hits_zero", 0, cache.hits)
			assert_integers_equal ("misses_zero", 0, cache.misses)
			assert_reals_equal ("hit_rate_zero", 0.0, cache.hit_rate, 0.001)
			cache.reset_statistics
			assert_integers_equal ("still_zero", 0, cache.hits)
		end

end
