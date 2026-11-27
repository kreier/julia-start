using Dates
using Printf
using Statistics

# 1. Define a custom immutable data structure for an expense entry
struct Expense
    id::Int
    date::Date
    category::Symbol
    description::String
    amount::Float64
end

# 2. Define a mutable container to manage the budget state
mutable struct BudgetLedger
    monthly_limit::Float64
    expenses::Vector{Expense}
    next_id::Int
end

# Outer constructor for easy initialization
BudgetLedger(monthly_limit::Real) = BudgetLedger(Float64(monthly_limit), Expense[], 1)

# 3. Core operations using Julia's multiple dispatch and mutating (!) conventions
function add_expense!(ledger::BudgetLedger, category::Symbol, description::String, amount::Real; date::Date=today())
    if amount <= 0
        throw(ArgumentError("Expense amount must be positive."))
    end
    entry = Expense(ledger.next_id, date, category, description, Float64(amount))
    push!(ledger.expenses, entry)
    ledger.next_id += 1
    return entry
end

function remove_expense!(ledger::BudgetLedger, id::Int)
    idx = findfirst(e -> e.id == id, ledger.expenses)
    if isnothing(idx)
        println("Warning: Expense ID #$id not found.")
        return false
    end
    deleteat!(ledger.expenses, idx)
    return true
end

# 4. Analytics & Reporting functions
total_spent(ledger::BudgetLedger) = isempty(ledger.expenses) ? 0.0 : sum(e.amount for e in ledger.expenses)
remaining_budget(ledger::BudgetLedger) = ledger.monthly_limit - total_spent(ledger)

function category_breakdown(ledger::BudgetLedger)
    totals = Dict{Symbol, Float64}()
    for e in ledger.expenses
        totals[e.category] = get(totals, e.category, 0.0) + e.amount
    end
    # Sort categories from highest spend to lowest
    return sort(collect(totals), by = x -> x[2], rev = true)
end

function print_report(ledger::BudgetLedger)
    println("\n" * "="^54)
    println("                 MONTHLY BUDGET REPORT")
    println("="^54)
    @printf("%-4s | %-10s | %-12s | %-14s | %8s\n", "ID", "Date", "Category", "Description", "Amount")
    println("-"^54)

    for e in ledger.expenses
        @printf("#%-3d | %-10s | %-12s | %-14s | \$%7.2f\n",
            e.id, e.date, e.category, first(e.description, 14), e.amount)
    end

    println("-"^54)
    println("Category Breakdown:")
    for (cat, amt) in category_breakdown(ledger)
        pct = (amt / total_spent(ledger)) * 100
        @printf("  • %-12s : \$%7.2f (%5.1f%%)\n", cat, amt, pct)
    end

    println("-"^54)
    spent = total_spent(ledger)
    rem = remaining_budget(ledger)
    avg = isempty(ledger.expenses) ? 0.0 : mean(e.amount for e in ledger.expenses)

    @printf("Monthly Budget   : \$%8.2f\n", ledger.monthly_limit)
    @printf("Total Spent      : \$%8.2f\n", spent)
    @printf("Average Expense  : \$%8.2f\n", avg)
    @printf("Remaining        : \$%8.2f %s\n", rem, rem < 0 ? "(OVER BUDGET)" : "")
    println("="^54 * "\n")
end

# 5. Interactive CLI Loop
function run_cli()
    println("Welcome to Julia Budget Tracker!")
    print("Enter your monthly budget (\$): ")
    limit_input = tryparse(Float64, readline())
    ledger = BudgetLedger(isnothing(limit_input) ? 1000.0 : limit_input)

    # Pre-populate with sample data so you can inspect a report immediately
    add_expense!(ledger, :Housing, "Electric Bill", 95.50; date=today() - Day(5))
    add_expense!(ledger, :Food, "Grocery Run", 142.30; date=today() - Day(3))
    add_expense!(ledger, :Transport, "Metro Pass", 45.00; date=today() - Day(1))

    while true
        println("\nOptions: [1] Add Expense  [2] Remove Expense  [3] View Report  [4] Exit")
        print("Choose an option: ")
        choice = strip(readline())

        if choice == "1"
            print("Category (e.g., Food, Rent, Fun): ")
            cat = Symbol(titlecase(strip(readline())))
            print("Description: ")
            desc = strip(readline())
            print("Amount (\$): ")
            amt = tryparse(Float64, readline())

            if isnothing(amt) || amt <= 0
                println("Invalid amount. Transaction cancelled.")
            else
                entry = add_expense!(ledger, cat, desc, amt)
                println("Added #$(entry.id): $(entry.description) (\$$(entry.amount))")
            end

        elseif choice == "2"
            print("Enter Expense ID to remove: ")
            id = tryparse(Int, readline())
            if !isnothing(id) && remove_expense!(ledger, id)
                println("Removed expense #$id.")
            end

        elseif choice == "3"
            print_report(ledger)

        elseif choice == "4"
            println("Goodbye!")
            break
        else
            println("Invalid selection. Enter 1, 2, 3, or 4.")
        end
    end
end

# Entry point guard (only runs CLI if executed directly, not when imported)
if abspath(PROGRAM_FILE) == @__FILE__
    run_cli()
end
