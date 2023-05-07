using Base: @kwdef
using Printf
using DataStructures: OrderedDict
using PDDL, SymbolicPlanners
using PDDLViz, GLMakie
using Gen, GenParticleFilters
using Plinf

using SymbolicPlanners: simplify_goal
using GenParticleFilters: softmax

include("recipe_utils.jl")

"Returns a weighted count of inferred recipe terms as a dictionary."
function recipe_term_counts_cb(pf::ParticleFilterView)
    traces = get_traces(pf)
    weights = get_norm_weights(pf)
    counts = Dict{Term, Float64}()
    for (tr, w) in zip(traces, weights)
        spec = tr[goal_addr]
        recipe = SymbolicPlanners.get_goal_terms(spec)[1]
        terms, vars = normalize_recipe(recipe)
        for term in terms
            if term.name in (Symbol("food-type"), Symbol("receptacle-type"))
                continue
            elseif isempty(vars) || PDDL.is_ground(term)
                counts[term] = get(counts, term, 0.0) + max(w, 0.0)
            else # Try and unify with existing term
                prev_count = get(counts, term, 0.0)
                if prev_count > 0.0
                    counts[term] += max(w, 0.0)
                else
                    unified = false
                    for k in keys(counts)
                        if !isnothing(PDDL.unify(term, k))
                            counts[k] += max(w, 0.0)
                            unified = true
                            break
                        end
                    end
                    if !unified
                        counts[term] = max(w, 0.0)
                    end
                end
            end
        end
    end
    return counts
end

"Returns the precision of inferred recipe terms with respect to the true goal."
function term_precision(true_goal::Term, term_counts::Dict{Term, Float64})
    terms, _ = normalize_recipe(true_goal)
    correct_weight = 0.0
    for (inferred_term, weight) in term_counts
        if inferred_term in terms
            correct_weight += weight
        elseif any(!isnothing(PDDL.unify(inferred_term, t)) for t in terms)
            correct_weight += weight
        end
    end
    precision = correct_weight / sum(values(term_counts))
    return precision
end

"Returns the recall of inferred recipe terms with respect to the true goal."
function term_recall(true_goal::Term, term_counts::Dict{Term, Float64})
    terms, _ = normalize_recipe(true_goal)
    filter!(terms) do term
        term.name in (Symbol("food-type"), Symbol("receptacle-type"))
    end
    correct_weight = 0.0
    for term in terms
        weight = get(term_counts, term, 0.0)
        if weight > 0.0
            correct_weight += weight
        else
            for (inferred_term, weight) in term_counts
                if !isnothing(PDDL.unify(inferred_term, term))
                    correct_weight += weight
                    break
                end
            end
        end
    end
    recall = correct_weight / length(terms)
    return recall
end

"Returns the F1 score of inferred recipe terms with respect to the true goal."
function term_f1_score(true_goal::Term, term_counts::Dict{Term, Float64})
    precision = term_precision(true_goal, term_counts)
    recall = term_recall(true_goal, term_counts)
    f1 = 2 * precision * recall / (precision + recall)
    return f1
end
