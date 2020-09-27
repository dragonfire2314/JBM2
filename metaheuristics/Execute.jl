module Execute

struct StoppingCriteria
    time_limit::Number
    use_time::Bool

    min_imp_amount::Number
    imp_timeframe::Float64
    use_min_rate::Bool

    max_apps::Int
    use_max_apps::Bool
end

function StoppingCriteria(; time_limit=10, min_imp_amount=-1,
        imp_timeframe=2, max_apps=-1)
    StoppingCriteria(
        time_limit,
        time_limit > 0,

        min_imp_amount,
        imp_timeframe,
        min_imp_amount > 0,

        max_apps,
        max_apps > 0
    )
end

function execute(data, descr_func, score_func,
        stopping_criteria::StoppingCriteria)
    num_apps = 0
    # imp_timeframe_start_score = \
    best_score = score_func(data)
    # next_check = time() + stopping_criteria.imp_timeframe
    # push!(exec.application_record, (exec.scorer(pop), time()) )
    start_time = time()

    gen_record = [(time(), 0, best_score)]

    while (!stopping_criteria.use_time ||
                time() - start_time < stopping_criteria.time_limit) &&
            (!stopping_criteria.use_max_apps ||
                (num_apps < stopping_criteria.max_apps))
        descr_func.exec(data)
        num_apps += 1

        new_score = score_func(data)
        if new_score > best_score
            push!(gen_record, (time(), num_apps, new_score))
            best_score = new_score
        end
        #TODO: implement the minimum improvement rate check
    end
    push!(gen_record, (time(), num_apps, best_score))

    gen_record
end

function make_exec(descr_func, score_func, stopping_criteria)
    function exec!(data)
        execute(data, descr_func, score_func, stopping_criteria)
    end
end

end
