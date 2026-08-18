(module
  (import "env" "memory" (memory 1))

  (func $header (param $index i32) (result i32)
    local.get $index
    i32.const 2
    i32.shl
    i32.load)

  (func $at (param $base i32) (param $index i32) (result i32)
    local.get $base
    local.get $index
    i32.const 2
    i32.shl
    i32.add
    i32.load)

  (func $put (param $base i32) (param $index i32) (param $value i32)
    local.get $base
    local.get $index
    i32.const 2
    i32.shl
    i32.add
    local.get $value
    i32.store)

  (func $mapped (param $state i32) (result i32)
    i32.const 0
    call $header
    local.get $state
    call $at)

  (func $matches (param $a i32) (param $b i32) (result i32)
    (local $kind i32)
    i32.const 7
    call $header
    local.get $a
    call $at
    local.tee $kind
    i32.const 7
    call $header
    local.get $b
    call $at
    i32.ne
    if
      i32.const 0
      return
    end
    local.get $kind
    i32.eqz
    if
      i32.const 8
      call $header
      local.get $a
      call $at
      call $mapped
      i32.const 8
      call $header
      local.get $b
      call $at
      call $mapped
      i32.eq
      return
    end
    i32.const 8
    call $header
    local.get $a
    call $at
    i32.const 8
    call $header
    local.get $b
    call $at
    i32.eq
    i32.const 9
    call $header
    local.get $a
    call $at
    i32.const 9
    call $header
    local.get $b
    call $at
    i32.eq
    i32.and)

  (func $actions_conflict
    (param $start_a i32) (param $end_a i32)
    (param $start_b i32) (param $end_b i32) (result i32)
    (local $i i32)
    (local $j i32)
    local.get $start_a
    local.set $i
    block $done
      loop $outer
        local.get $i
        local.get $end_a
        i32.ge_u
        br_if $done
        local.get $start_b
        local.set $j
        block $inner_done
          loop $inner
            local.get $j
            local.get $end_b
            i32.ge_u
            br_if $inner_done
            local.get $i
            local.get $j
            call $matches
            i32.eqz
            if
              i32.const 1
              return
            end
            local.get $j
            i32.const 1
            i32.add
            local.set $j
            br $inner
          end
        end
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $outer
      end
    end
    i32.const 0)

  (func $has_match
    (param $action i32) (param $start i32) (param $end i32) (result i32)
    (local $i i32)
    local.get $start
    local.set $i
    block $done
      loop $loop
        local.get $i
        local.get $end
        i32.ge_u
        br_if $done
        local.get $action
        local.get $i
        call $matches
        if
          i32.const 1
          return
        end
        local.get $i
        i32.const 1
        i32.add
        local.set $i
        br $loop
      end
    end
    i32.const 0)

  (func $can_merge (export "can_merge") (param $a i32) (param $b i32) (result i32)
    (local $goto_a i32)
    (local $goto_a_end i32)
    (local $goto_b i32)
    (local $goto_b_end i32)
    (local $term_a i32)
    (local $term_b i32)
    (local $shift_a i32)
    (local $reduce_a i32)
    (local $shift_b i32)
    (local $reduce_b i32)
    (local $split_a i32)
    (local $split_b i32)
    (local $end_a i32)
    (local $end_b i32)
    (local $term i32)
    (local $end_shift_a i32)
    (local $end_reduce_a i32)
    (local $end_shift_b i32)
    (local $end_reduce_b i32)
    (local $count_a i32)
    (local $count_b i32)
    (local $conflict i32)
    (local $i i32)

    i32.const 1
    call $header
    local.get $a
    call $at
    local.set $goto_a
    i32.const 1
    call $header
    local.get $a
    i32.const 1
    i32.add
    call $at
    local.set $goto_a_end
    i32.const 1
    call $header
    local.get $b
    call $at
    local.set $goto_b
    i32.const 1
    call $header
    local.get $b
    i32.const 1
    i32.add
    call $at
    local.set $goto_b_end

    block $goto_done
      loop $goto_loop
        local.get $goto_a
        local.get $goto_a_end
        i32.ge_u
        br_if $goto_done
        local.get $goto_b
        local.get $goto_b_end
        i32.ge_u
        br_if $goto_done
        i32.const 2
        call $header
        local.get $goto_a
        call $at
        local.set $term_a
        i32.const 2
        call $header
        local.get $goto_b
        call $at
        local.set $term_b
        local.get $term_a
        local.get $term_b
        i32.eq
        if
          i32.const 3
          call $header
          local.get $goto_a
          call $at
          call $mapped
          i32.const 3
          call $header
          local.get $goto_b
          call $at
          call $mapped
          i32.ne
          if
            i32.const 0
            return
          end
          local.get $goto_a
          i32.const 1
          i32.add
          local.set $goto_a
          local.get $goto_b
          i32.const 1
          i32.add
          local.set $goto_b
        else
          local.get $term_a
          local.get $term_b
          i32.lt_s
          if
            local.get $goto_a
            i32.const 1
            i32.add
            local.set $goto_a
          else
            local.get $goto_b
            i32.const 1
            i32.add
            local.set $goto_b
          end
        end
        br $goto_loop
      end
    end

    i32.const 4
    call $header
    local.get $a
    call $at
    local.set $shift_a
    i32.const 5
    call $header
    local.get $a
    call $at
    local.tee $split_a
    local.set $reduce_a
    i32.const 4
    call $header
    local.get $a
    i32.const 1
    i32.add
    call $at
    local.set $end_a
    i32.const 4
    call $header
    local.get $b
    call $at
    local.set $shift_b
    i32.const 5
    call $header
    local.get $b
    call $at
    local.tee $split_b
    local.set $reduce_b
    i32.const 4
    call $header
    local.get $b
    i32.const 1
    i32.add
    call $at
    local.set $end_b

    block $actions_done
      loop $actions_loop
        i32.const 2147483647
        local.set $term_a
        local.get $shift_a
        local.get $split_a
        i32.lt_u
        if
          i32.const 6
          call $header
          local.get $shift_a
          call $at
          local.set $term_a
        end
        i32.const 2147483647
        local.set $term_b
        local.get $reduce_a
        local.get $end_a
        i32.lt_u
        if
          i32.const 6
          call $header
          local.get $reduce_a
          call $at
          local.set $term_b
        end
        local.get $term_a
        local.get $term_b
        i32.lt_s
        if
          local.get $term_a
          local.set $term
        else
          local.get $term_b
          local.set $term
        end
        local.get $term
        i32.const 2147483647
        i32.eq
        br_if $actions_done

        block $advance_shift_b_done
          loop $advance_shift_b
            local.get $shift_b
            local.get $split_b
            i32.ge_u
            br_if $advance_shift_b_done
            i32.const 6
            call $header
            local.get $shift_b
            call $at
            local.get $term
            i32.ge_s
            br_if $advance_shift_b_done
            local.get $shift_b
            i32.const 1
            i32.add
            local.set $shift_b
            br $advance_shift_b
          end
        end
        block $advance_reduce_b_done
          loop $advance_reduce_b
            local.get $reduce_b
            local.get $end_b
            i32.ge_u
            br_if $advance_reduce_b_done
            i32.const 6
            call $header
            local.get $reduce_b
            call $at
            local.get $term
            i32.ge_s
            br_if $advance_reduce_b_done
            local.get $reduce_b
            i32.const 1
            i32.add
            local.set $reduce_b
            br $advance_reduce_b
          end
        end

        local.get $shift_a
        local.set $end_shift_a
        block $end_shift_a_done
          loop $end_shift_a_loop
            local.get $end_shift_a
            local.get $split_a
            i32.ge_u
            br_if $end_shift_a_done
            i32.const 6
            call $header
            local.get $end_shift_a
            call $at
            local.get $term
            i32.ne
            br_if $end_shift_a_done
            local.get $end_shift_a
            i32.const 1
            i32.add
            local.set $end_shift_a
            br $end_shift_a_loop
          end
        end
        local.get $reduce_a
        local.set $end_reduce_a
        block $end_reduce_a_done
          loop $end_reduce_a_loop
            local.get $end_reduce_a
            local.get $end_a
            i32.ge_u
            br_if $end_reduce_a_done
            i32.const 6
            call $header
            local.get $end_reduce_a
            call $at
            local.get $term
            i32.ne
            br_if $end_reduce_a_done
            local.get $end_reduce_a
            i32.const 1
            i32.add
            local.set $end_reduce_a
            br $end_reduce_a_loop
          end
        end
        local.get $shift_b
        local.set $end_shift_b
        block $end_shift_b_done
          loop $end_shift_b_loop
            local.get $end_shift_b
            local.get $split_b
            i32.ge_u
            br_if $end_shift_b_done
            i32.const 6
            call $header
            local.get $end_shift_b
            call $at
            local.get $term
            i32.ne
            br_if $end_shift_b_done
            local.get $end_shift_b
            i32.const 1
            i32.add
            local.set $end_shift_b
            br $end_shift_b_loop
          end
        end
        local.get $reduce_b
        local.set $end_reduce_b
        block $end_reduce_b_done
          loop $end_reduce_b_loop
            local.get $end_reduce_b
            local.get $end_b
            i32.ge_u
            br_if $end_reduce_b_done
            i32.const 6
            call $header
            local.get $end_reduce_b
            call $at
            local.get $term
            i32.ne
            br_if $end_reduce_b_done
            local.get $end_reduce_b
            i32.const 1
            i32.add
            local.set $end_reduce_b
            br $end_reduce_b_loop
          end
        end

        local.get $end_shift_a
        local.get $shift_a
        i32.sub
        local.get $end_reduce_a
        local.get $reduce_a
        i32.sub
        i32.add
        local.set $count_a
        local.get $end_shift_b
        local.get $shift_b
        i32.sub
        local.get $end_reduce_b
        local.get $reduce_b
        i32.sub
        i32.add
        local.tee $count_b
        if
          local.get $shift_a
          local.get $end_shift_a
          local.get $shift_b
          local.get $end_shift_b
          call $actions_conflict
          local.get $shift_a
          local.get $end_shift_a
          local.get $reduce_b
          local.get $end_reduce_b
          call $actions_conflict
          i32.or
          local.get $reduce_a
          local.get $end_reduce_a
          local.get $shift_b
          local.get $end_shift_b
          call $actions_conflict
          i32.or
          local.get $reduce_a
          local.get $end_reduce_a
          local.get $reduce_b
          local.get $end_reduce_b
          call $actions_conflict
          i32.or
          local.tee $conflict
          if
            local.get $count_b
            i32.const 1
            i32.eq
            local.get $count_a
            local.get $count_b
            i32.ne
            i32.or
            if
              i32.const 0
              return
            end
            local.get $shift_a
            local.set $i
            block $match_shifts_done
              loop $match_shifts
                local.get $i
                local.get $end_shift_a
                i32.ge_u
                br_if $match_shifts_done
                local.get $i
                local.get $shift_b
                local.get $end_shift_b
                call $has_match
                local.get $i
                local.get $reduce_b
                local.get $end_reduce_b
                call $has_match
                i32.or
                i32.eqz
                if
                  i32.const 0
                  return
                end
                local.get $i
                i32.const 1
                i32.add
                local.set $i
                br $match_shifts
              end
            end
            local.get $reduce_a
            local.set $i
            block $match_reduces_done
              loop $match_reduces
                local.get $i
                local.get $end_reduce_a
                i32.ge_u
                br_if $match_reduces_done
                local.get $i
                local.get $shift_b
                local.get $end_shift_b
                call $has_match
                local.get $i
                local.get $reduce_b
                local.get $end_reduce_b
                call $has_match
                i32.or
                i32.eqz
                if
                  i32.const 0
                  return
                end
                local.get $i
                i32.const 1
                i32.add
                local.set $i
                br $match_reduces
              end
            end
          end
        end

        local.get $end_shift_a
        local.set $shift_a
        local.get $end_reduce_a
        local.set $reduce_a
        local.get $end_shift_b
        local.set $shift_b
        local.get $end_reduce_b
        local.set $reduce_b
        br $actions_loop
      end
    end
    i32.const 1)

  (func $set_mapping (param $state i32) (param $group i32)
    (local $epoch i32)
    i32.const 0
    call $header
    local.get $state
    call $at
    local.get $group
    i32.ne
    if
      i32.const 0
      call $header
      local.get $state
      local.get $group
      call $put
      i32.const 20
      call $header
      i32.const 1
      call $at
      i32.const 1
      i32.add
      local.set $epoch
      i32.const 20
      call $header
      i32.const 1
      local.get $epoch
      call $put
      i32.const 19
      call $header
      local.get $state
      local.get $epoch
      call $put
    end)

  (func $stale (param $group i32) (result i32)
    (local $verified i32)
    (local $member i32)
    (local $p i32)
    (local $end i32)
    i32.const 16
    call $header
    local.get $group
    call $at
    local.set $verified
    i32.const 12
    call $header
    local.get $group
    call $at
    local.set $member
    block $members_done
      loop $members
        local.get $member
        i32.const 0
        i32.lt_s
        br_if $members_done
        i32.const 10
        call $header
        local.get $member
        call $at
        local.set $p
        i32.const 10
        call $header
        local.get $member
        i32.const 1
        i32.add
        call $at
        local.set $end
        block $deps_done
          loop $deps
            local.get $p
            local.get $end
            i32.ge_u
            br_if $deps_done
            i32.const 19
            call $header
            i32.const 11
            call $header
            local.get $p
            call $at
            call $at
            local.get $verified
            i32.gt_s
            if
              i32.const 1
              return
            end
            local.get $p
            i32.const 1
            i32.add
            local.set $p
            br $deps
          end
        end
        i32.const 17
        call $header
        local.get $member
        call $at
        local.set $member
        br $members
      end
    end
    i32.const 0)

  (func $remove_swap (param $group i32) (param $state i32) (result i32)
    (local $tail i32)
    (local $prev_state i32)
    (local $next_state i32)
    (local $prev_tail i32)
    (local $length i32)
    i32.const 13
    call $header
    local.get $group
    call $at
    local.set $tail
    i32.const 18
    call $header
    local.get $state
    call $at
    local.set $prev_state
    i32.const 17
    call $header
    local.get $state
    call $at
    local.set $next_state

    local.get $state
    local.get $tail
    i32.eq
    if
      local.get $prev_state
      i32.const 0
      i32.ge_s
      if
        i32.const 17
        call $header
        local.get $prev_state
        i32.const -1
        call $put
        i32.const 13
        call $header
        local.get $group
        local.get $prev_state
        call $put
      else
        i32.const 12
        call $header
        local.get $group
        i32.const -1
        call $put
        i32.const 13
        call $header
        local.get $group
        i32.const -1
        call $put
      end
    else
      i32.const 18
      call $header
      local.get $tail
      call $at
      local.set $prev_tail
      i32.const 17
      call $header
      local.get $prev_tail
      i32.const -1
      call $put
      i32.const 13
      call $header
      local.get $group
      local.get $prev_tail
      call $put

      i32.const 18
      call $header
      local.get $tail
      local.get $prev_state
      call $put
      local.get $prev_state
      i32.const 0
      i32.ge_s
      if
        i32.const 17
        call $header
        local.get $prev_state
        local.get $tail
        call $put
      else
        i32.const 12
        call $header
        local.get $group
        local.get $tail
        call $put
      end

      local.get $next_state
      local.get $tail
      i32.eq
      if
        i32.const 17
        call $header
        local.get $tail
        i32.const -1
        call $put
        i32.const 13
        call $header
        local.get $group
        local.get $tail
        call $put
      else
        i32.const 17
        call $header
        local.get $tail
        local.get $next_state
        call $put
        i32.const 18
        call $header
        local.get $next_state
        local.get $tail
        call $put
      end
    end

    i32.const 17
    call $header
    local.get $state
    i32.const -1
    call $put
    i32.const 18
    call $header
    local.get $state
    i32.const -1
    call $put
    i32.const 14
    call $header
    local.get $group
    call $at
    i32.const 1
    i32.sub
    local.set $length
    i32.const 14
    call $header
    local.get $group
    local.get $length
    call $put
    local.get $state
    local.get $tail
    i32.eq
    if (result i32)
      i32.const -1
    else
      local.get $tail
    end)

  (func $append (param $group i32) (param $state i32)
    (local $tail i32)
    i32.const 13
    call $header
    local.get $group
    call $at
    local.set $tail
    local.get $tail
    i32.const 0
    i32.ge_s
    if
      i32.const 17
      call $header
      local.get $tail
      local.get $state
      call $put
    else
      i32.const 12
      call $header
      local.get $group
      local.get $state
      call $put
    end
    i32.const 18
    call $header
    local.get $state
    local.get $tail
    call $put
    i32.const 17
    call $header
    local.get $state
    i32.const -1
    call $put
    i32.const 13
    call $header
    local.get $group
    local.get $state
    call $put
    i32.const 14
    call $header
    local.get $group
    i32.const 14
    call $header
    local.get $group
    call $at
    i32.const 1
    i32.add
    call $put)

  (func $all_merge (param $state i32) (param $group i32) (result i32)
    (local $member i32)
    i32.const 12
    call $header
    local.get $group
    call $at
    local.set $member
    block $done
      loop $members
        local.get $member
        i32.const 0
        i32.lt_s
        br_if $done
        local.get $state
        local.get $member
        call $can_merge
        i32.eqz
        if
          i32.const 0
          return
        end
        i32.const 17
        call $header
        local.get $member
        call $at
        local.set $member
        br $members
      end
    end
    i32.const 1)

  (func $spill (param $group i32) (param $state i32) (result i32)
    (local $replacement i32)
    (local $origin i32)
    (local $candidate i32)
    (local $count i32)
    local.get $group
    local.get $state
    call $remove_swap
    local.set $replacement
    i32.const 15
    call $header
    local.get $group
    call $at
    local.set $origin
    local.get $group
    i32.const 1
    i32.add
    local.set $candidate
    i32.const 20
    call $header
    i32.const 0
    call $at
    local.set $count
    block $search_done
      loop $search
        local.get $candidate
        local.get $count
        i32.ge_u
        br_if $search_done
        local.get $state
        local.get $candidate
        call $set_mapping
        i32.const 15
        call $header
        local.get $candidate
        call $at
        local.get $origin
        i32.eq
        if
          local.get $state
          local.get $candidate
          call $all_merge
          if
            local.get $candidate
            local.get $state
            call $append
            i32.const 16
            call $header
            local.get $candidate
            i32.const 0
            call $put
            local.get $replacement
            return
          end
        end
        local.get $candidate
        i32.const 1
        i32.add
        local.set $candidate
        br $search
      end
    end

    local.get $state
    local.get $count
    call $set_mapping
    i32.const 12
    call $header
    local.get $count
    local.get $state
    call $put
    i32.const 13
    call $header
    local.get $count
    local.get $state
    call $put
    i32.const 14
    call $header
    local.get $count
    i32.const 1
    call $put
    i32.const 15
    call $header
    local.get $count
    local.get $origin
    call $put
    i32.const 16
    call $header
    local.get $count
    i32.const 0
    call $put
    i32.const 17
    call $header
    local.get $state
    i32.const -1
    call $put
    i32.const 18
    call $header
    local.get $state
    i32.const -1
    call $put
    i32.const 20
    call $header
    i32.const 0
    local.get $count
    i32.const 1
    i32.add
    call $put
    local.get $replacement)

  (func (export "collapse") (result i32)
    (local $pass i32)
    (local $conflicts i32)
    (local $start_count i32)
    (local $group i32)
    (local $verified i32)
    (local $spilled i32)
    (local $state_a i32)
    (local $state_b i32)
    (local $scanned i32)
    (local $skipped i32)
    loop $passes
      local.get $pass
      i32.const 1
      i32.add
      local.set $pass
      i32.const 0
      local.set $conflicts
      i32.const 20
      call $header
      i32.const 0
      call $at
      local.set $start_count
      i32.const 0
      local.set $group
      block $groups_done
        loop $groups
          local.get $group
          local.get $start_count
          i32.ge_u
          br_if $groups_done
          i32.const 14
          call $header
          local.get $group
          call $at
          i32.const 2
          i32.ge_u
          if
            i32.const 16
            call $header
            local.get $group
            call $at
            i32.eqz
            if
            else
              local.get $group
              call $stale
              i32.eqz
              if
                local.get $skipped
                i32.const 1
                i32.add
                local.set $skipped
                local.get $group
                i32.const 1
                i32.add
                local.set $group
                br $groups
              end
            end
            local.get $scanned
            i32.const 1
            i32.add
            local.set $scanned
            i32.const 20
            call $header
            i32.const 1
            call $at
            local.set $verified
            i32.const 0
            local.set $spilled
            i32.const 12
            call $header
            local.get $group
            call $at
            local.set $state_a
            block $outer_done
              loop $outer
                local.get $state_a
                i32.const 0
                i32.lt_s
                br_if $outer_done
                i32.const 17
                call $header
                local.get $state_a
                call $at
                local.set $state_b
                block $inner_done
                  loop $inner
                    local.get $state_b
                    i32.const 0
                    i32.lt_s
                    br_if $inner_done
                    local.get $state_a
                    local.get $state_b
                    call $can_merge
                    if
                      i32.const 17
                      call $header
                      local.get $state_b
                      call $at
                      local.set $state_b
                    else
                      i32.const 1
                      local.set $conflicts
                      i32.const 1
                      local.set $spilled
                      local.get $group
                      local.get $state_b
                      call $spill
                      local.set $state_b
                    end
                    br $inner
                  end
                end
                i32.const 17
                call $header
                local.get $state_a
                call $at
                local.set $state_a
                br $outer
              end
            end
            i32.const 16
            call $header
            local.get $group
            local.get $spilled
            if (result i32)
              i32.const 0
            else
              local.get $verified
            end
            call $put
          end
          local.get $group
          i32.const 1
          i32.add
          local.set $group
          br $groups
        end
      end
      local.get $conflicts
      br_if $passes
    end
    i32.const 20
    call $header
    i32.const 2
    local.get $pass
    call $put
    i32.const 20
    call $header
    i32.const 3
    local.get $scanned
    call $put
    i32.const 20
    call $header
    i32.const 4
    local.get $skipped
    call $put
    local.get $pass)
)
