note
	description: "Three-tier fixture hierarchy for simple_cache tests"
	author: "Larry Rix with Claude (Anthropic)"
	date: "$Date$"
	revision: "$Revision$"

class
	CACHE_FIXTURES

inherit
	TEST_SET_BASE

feature -- Tier 1: Empty Cache

	empty_cache: SIMPLE_CACHE [STRING]
			-- Fresh cache with no entries (recreated each access)
		do
			create Result.make (10)
		ensure
			cache_created: Result /= Void
			is_empty: Result.is_empty
			count_zero: Result.count = 0
		end

	empty_small_cache: SIMPLE_CACHE [STRING]
			-- Small cache for LRU testing (recreated each access)
		do
			create Result.make (3)
		ensure
			cache_created: Result /= Void
			small_capacity: Result.max_size = 3
			is_empty: Result.is_empty
		end

	empty_integer_cache: SIMPLE_CACHE [INTEGER]
			-- Empty cache for integer values (recreated each access)
		do
			create Result.make (10)
		ensure
			cache_created: Result /= Void
			is_empty: Result.is_empty
		end

feature -- Tier 2: Populated LRU Cache

	lru_populated_cache: SIMPLE_CACHE [STRING]
			-- Cache with 3 entries, ready for LRU eviction tests
		once
			create Result.make (3)
			Result.put ("a", "1")
			Result.put ("b", "2")
			Result.put ("c", "3")
		ensure
			cache_full: Result.is_full
			count_three: Result.count = 3
			has_all_entries: Result.has ("a") and Result.has ("b") and Result.has ("c")
		end

	cache_with_ttl: SIMPLE_CACHE [STRING]
			-- Cache with TTL enabled
		once
			create Result.make_with_ttl (10, 3600)
		ensure
			cache_created: Result /= Void
			ttl_set: Result.default_ttl = 3600
			is_empty: Result.is_empty
		end

feature -- Tier 3: Cache with Statistics History

	stats_established_cache: SIMPLE_CACHE [STRING]
			-- Cache with accumulated hit/miss statistics
		local
			l_temp: detachable STRING
		once
			create Result.make (10)
			Result.put ("key1", "value1")
			l_temp := Result.get ("key1")
			l_temp := Result.get ("key1")
			l_temp := Result.get ("missing")
		ensure
			has_data: Result.count = 1
			hits_tracked: Result.hits = 2
			misses_tracked: Result.misses = 1
		end

	exhausted_cache: SIMPLE_CACHE [STRING]
			-- Cache at capacity with evictions performed
		local
			i: INTEGER
		once
			create Result.make (2)
			Result.put ("a", "1")
			Result.put ("b", "2")
			Result.put ("c", "3")
			Result.put ("d", "4")
		ensure
			at_capacity: Result.is_full
			count_two: Result.count = 2
			evictions_occurred: Result.evictions = 2
		end

end
