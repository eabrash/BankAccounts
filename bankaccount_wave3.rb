# bankaccount.rb
#
# Represents a bank account. Learning about using modules.

require "csv"

module Bank

  # Class holding basic information on owner of a bank account. This was made
  # in an effort to respect the "single responsiblity principle," since it did
  # not seem like this association behavior properly belonged to either owner
  # or Account. This and other functionality might best reside in a Bank class
  # or some other, higher-level class.

  class AccountLinker

    def self.read_account_owner_associations(csv_file)

      linker = CSV.read(csv_file)

      # Associate account ID with owner and vice versa

      linker.each do |link|
          target_account = Bank::Account.find(Integer(link[0]))
          target_owner = Bank::Owner.find(Integer(link[1]))
          target_account.add_owner(Integer(link[1]))
          target_owner.add_account(Integer(link[0]))
      end

    end

  end

  # Class representing an account owner.

  class Owner

    attr_reader :id, :name, :address, :account_IDs

    # The owner hash contains two smaller hashes. The hash accessed by :name
    # has sub-keys :first, :middle, and :last. The hash accessed by :address
    # has sub-keys :street1, :street2, :city, :state, :country, and :zip. Not
    # every field will be provided for every owner.

    @@all_owners = []   # Class variable - array of all owners

    def initialize(owner_hash)
      @id = owner_hash[:id]
      @name = owner_hash[:name]
      @address = owner_hash[:address]
      @account_IDs = []
    end

    # Read in owners from CSV file, create Owner objects stored in @@all_owners

    def self.read_owners(csv_file)

      owners = CSV.read(csv_file)

      owners.each do |owner|
          @@all_owners << Bank::Owner.new({ id: Integer(owner[0]), name: { last: owner[1], first: owner[2]}, address: { street1: owner[3], city: owner[4], state: owner[5]} } )
      end

    end

    # Return array of all owners

    def self.all
      return @@all_owners
    end

    # Find the Owner object that matches the given ID

    def self.find (desired_ID)

      target_array = @@all_owners.select{ |owner| owner.id == desired_ID }

      if target_array.length == 0
        return nil
      elsif target_array.length > 1
        raise StandardError, "There are multiple owners with the same ID."   # There are multiple owner instances with the same ID number -- BAD
      else
        return target_array[0]
      end

    end

    # Associate the provided account ID with this owner. This is an array
    # because the same owner could have multiple accounts.

    def add_account(account_ID)
      if @account_IDs[0] == nil
        @account_IDs = [account_ID]
      else
        @account_IDs << account_ID
      end
    end

    # Return a printable version of owner's name and address

    def to_s
      return "#{@id}: #{@name[:first]} #{@name[:middle]} #{@name[:last]}\n#{@address[:street1]}\t #{@address[:street2]}\n#{@address[:city]}, #{@address[:state]} #{@address[:zip]}\t#{@address[:country]}\n\n"
    end

  end

  # Class representing a bank account. Provides methods to allow transactions.

  class Account

    attr_reader :balance, :owners, :id, :creation_date

    @@all_accounts = []

    # Initialize account with account data input. An owner can optionally be provided
    # upon initialization, but this functionality is not used in the current version of
    # the program.

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      @id = account_ID
      @owners = [account_owner]
      @creation_date = date_of_creation

      # Negative starting balance produces an error

      if account_initial_balance >= 0
        @balance = Float(account_initial_balance)
      else
        raise ArgumentError
      end

    end

    # Read in information from a CSV and store it in the @@all_accounts class
    # variable. Money is currently stored as a Float in dollars, not as an
    # integer representing total number of cents.

    def self.read_accounts(csv_file)

      accounts = CSV.read(csv_file)

      accounts.each do |account|
          @@all_accounts << Bank::Account.new(Integer(account[0]), Float(account[1])/100.0, DateTime.parse(account[2]))
      end

    end

    # Return list of all Accounts that have been created. I don't think this is
    # the optimal way to store accounts in the long term, as this is really
    # something that should be separately represented or pertain to a Bank
    # object (if we were to make Bank a class rather than a module).

    def self.all
      return @@all_accounts
    end

    # Return the Account with the given ID

    def self.find (desired_ID)

      target_array = @@all_accounts.select{ |account| account.id == desired_ID }

      if target_array.length == 0
        return nil
      elsif target_array.length > 1
        raise StandardError, "There are multiple accounts with the same ID."   # There are multiple account instances with the same ID number -- BAD
      else
        return target_array[0]
      end

    end

    # Withdraw a specified amount of money. If the account does not contain
    # enough money to support the withdrawal, a message is given to the user
    # and no money is withdrawn.

    def withdraw(amount_to_withdraw)

      if amount_to_withdraw <= @balance
        @balance -= amount_to_withdraw
      else
        puts "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + ". No withdrawal was made."
      end

      return @balance

    end

    # Deposit a specified amount of money.

    def deposit(amount_to_deposit)
      @balance += amount_to_deposit
      return @balance
    end

    # If there is no owner from initialization, make the added owner the owner.
    # If there is already an owner, add a second owner.

    def add_owner(owner_ID)
      if @owners[0] == nil
        @owners = [owner_ID]
      else
        @owners << owner_ID
      end
    end

    # String description of account's basic properties.

    def to_s
      return "ID: " + @id.to_s + ", Balance: $%.2f" % @balance + ", Date of creation: " + @creation_date.to_s
    end

  end

  class SavingsAccount < Bank::Account

    FEE = 2.0
    MIN_BAL = 10.0

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      super   # This is kind of sloppy to call here because it will still do the < 0 check and assign the balance
              # before throwing the error below if the balance is between $0 and $10

      if account_initial_balance < MIN_BAL
        raise ArgumentError
      end

    end

    def withdraw(amount_to_withdraw)

      if amount_to_withdraw <= @balance - MIN_BAL - FEE
        @balance -= amount_to_withdraw + FEE
      else
        puts "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + ". Remember, you must keep $%.2f" % MIN_BAL + " in your savings account at all times, and a $%.2f" % FEE + " fee is incurred for each withdrawal. No withdrawal was made."
      end

      return @balance

    end

    def add_interest(rate)
      interest = @balance * rate/100.0
      @balance += interest
      return interest
    end

  end

  class CheckingAccount < Bank::Account

    NON_CHECK_WITHDRAWAL_FEE = 1.0
    CHECK_WITHDRAWAL_FEE = 2.0
    FREE_CHECKS_PER_MONTH = 3
    MAX_ALLOWABLE_OVERDRAFT = 10.0

    attr_reader :free_checks_available

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      super

      @free_checks_available = FREE_CHECKS_PER_MONTH

    end

    def withdraw(amount_to_withdraw)

      if amount_to_withdraw <= @balance - NON_CHECK_WITHDRAWAL_FEE
        @balance -= amount_to_withdraw + NON_CHECK_WITHDRAWAL_FEE
      else
        puts "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + " by direct withdrawal. Remember that a $%.2f" % NON_CHECK_WITHDRAWAL_FEE + " fee is incurred for each withdrawal. No withdrawal was made."
      end

      return @balance

    end

    def withdraw_using_check(amount_to_withdraw)

      transaction_fee = 0.0

      if @free_checks_available <= 0
        transaction_fee = CHECK_WITHDRAWAL_FEE
      else
        @free_checks_available -= 1
      end

      if amount_to_withdraw <= @balance - transaction_fee + MAX_ALLOWABLE_OVERDRAFT

        @balance -= amount_to_withdraw + transaction_fee

      else

        print "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + ". Remember that you can only have a maximum overdraft of $-%.2f" % MAX_ALLOWABLE_OVERDRAFT + "."

        if transaction_fee == CHECK_WITHDRAWAL_FEE
          print " Also, a $%.2f" % CHECK_WITHDRAWAL_FEE + " fee would be charged, because you've already used up your #{FREE_CHECKS_PER_MONTH} free check withdrawals for this month."
        end

        print " No withdrawal was made.\n"

      end

      return @balance

    end

    def reset_checks
      @free_checks_available = FREE_CHECKS_PER_MONTH
    end

  end

  class MoneyMarketAccount < Bank::Account

    MAX_TRANSACTIONS = 6
    MIN_BAL = 10000.0
    BELOW_MINIMUM_FEE = 100.0

    attr_reader :transactions_remaining

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      super

      if account_initial_balance < MIN_BAL
        raise ArgumentError
      end

      @transactions_remaining = MAX_TRANSACTIONS
      @frozen = false

    end

    def withdraw(amount_to_withdraw)

      if @frozen
        puts "Sorry, you cannot perform transactions right now. Your account is frozen because it is below the minimum balance of $%.2f" % MIN_BAL + "."
        return @balance
      end

      if @transactions_remaining == 0
        puts "Sorry, you cannot perform transactions right now. You have already used your #{MAX_TRANSACTIONS} transactions for the month."
        return @balance
      end

      # Prevent a withdrawal that will send the balance negative (after $100 fee)

      if amount_to_withdraw <= @balance - BELOW_MINIMUM_FEE

        @balance -= amount_to_withdraw

        # Penalize a dip below minimum account balance

        if balance < MIN_BAL
          @balance -= BELOW_MINIMUM_FEE
          puts "You have incurred a $%.2f" % BELOW_MINIMUM_FEE + " fee for letting your account balance drop below $%.2f" % MIN_BAL + ". You will not be able to make further withdrawals until you bring your balance above $%.2f" % MIN_BAL + " again."
          @frozen = true
        end

        @transactions_remaining -= 1

      else

        puts "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + ". Remember that a $%.2f" % BELOW_MINIMUM_FEE + " fee is incurred for withdrawals that bring the account balance below $%.2f" % MIN_BAL + ". No withdrawal was made."

      end

      return @balance

    end

    def deposit(amount_to_deposit)

      if @frozen

        @balance += amount_to_deposit

        if @balance > MIN_BAL
          @frozen = false
          puts "Thank you - you have exceeded the minimum balance of $%.2f" % MIN_BAL + ", and your account is unfrozen."
        end

      else

        if @transactions_remaining == 0
          puts "Sorry, you cannot perform transactions right now. You have already used your #{MAX_TRANSACTIONS} transactions for the month."
        else
          @balance += amount_to_deposit
          @transactions_remaining -= 1
        end

      end

      return @balance

    end

    def add_interest(rate)

      interest = @balance * rate/100.0
      @balance += interest
      return interest

    end

    def reset_transactions
      @transactions_remaining = MAX_TRANSACTIONS
    end

  end

end

Bank::Account.read_accounts("./support/accounts.csv")
Bank::Owner.read_owners("./support/owners.csv")
Bank::AccountLinker.read_account_owner_associations("./support/account_owners.csv")

my_moneymarket = Bank::MoneyMarketAccount.new(13240, 20000.0, Time.now, 15)
puts my_moneymarket

7.times do
  puts "Depositing $10..."
  new_bal = my_moneymarket.deposit(10.0)
  puts "New balance: $%.2f" % new_bal
end

my_moneymarket.reset_transactions

puts "\nWithdrawing $15000..."
new_bal = my_moneymarket.withdraw(15000.0)
puts "New balance: $%.2f" % new_bal

# # Testing basic functionality of SavingsAccount
#
# my_savings = Bank::SavingsAccount.new(13240, 15.0, Time.now, 15)
# puts my_savings
# puts Bank::Owner.find(my_savings.owners[0])
#
# puts "Let's deposit $10"
# new_bal = my_savings.deposit(10.0)
# puts "Balance is now: $%.2f" % new_bal
#
# puts "Let's withdraw $10"
# new_bal = my_savings.withdraw(10.0)
# puts "Balance is now $%.2f" % new_bal
#
# puts "Let's withdraw $10 more"
# new_bal = my_savings.withdraw(10.0)
# puts "Balance is now $%.2f" % new_bal
#
# # Checking that a SavingsAccount initialized with less that $10 balance will raise
# # an ArgumentError
#
# puts "\nLet's try to start a new savings account with a $9.99 balance..."
#
# begin
#   my_savings2 = Bank::SavingsAccount.new(13240, 9.99, Time.now, 15)
# rescue ArgumentError
#   puts "Sorry, a minimum $%.2f" % Bank::SavingsAccount::MIN_BAL + " balance is required to start a new savings account."
# end
#
# # Testing the add_interest(rate) method
#
# my_savings3 = Bank::SavingsAccount.new(13250, 10000.0, Time.now)
# puts my_savings3
#
# print "Interest accrued on savings: "
# interest = my_savings3.add_interest(0.25)
# print "$%.2f" % interest + "\n"
# puts my_savings3
#
# # Testing CheckingAccount functionality
#
# puts "\n Testing CheckingAccount..."
#
# my_checking3 = Bank::CheckingAccount.new(144070, 10000.0, Time.now)
# puts my_checking3
#
# # Test basic withdrawal - $1 fee should be charged
#
# puts "Withdrawing $10"
# new_bal = my_checking3.withdraw(10)
# puts "The balance is now: $%.2f" % new_bal
#
# # Test check withdrawal (should be free first 3 times, then charge $2 fee thereafter
# # until reset)
#
# 4.times do
#
#   puts "\nWithdrawing $10 by check (second check)"
#   new_bal = my_checking3.withdraw_using_check(10)
#   puts "The balance is now: $%.2f" % new_bal
#
# end
#
# puts "\nResetting to #{Bank::CheckingAccount::FREE_CHECKS_PER_MONTH} free check withdrawals (it's a new month)..."
# my_checking3.reset_checks
# puts  "Withdrawing $10 by check (first check since reset)"
# new_bal = my_checking3.withdraw_using_check(10)
# puts "The balance is now: $%.2f" % new_bal
#
# # Test check withdrawal overdraft feature
#
# puts "\n\nLet's test the overdraft feature..."
#
# my_checking4 = Bank::CheckingAccount.new(144070, 20.0, Time.now)
# puts my_checking4
#
# 4.times do
#
#   puts "\nWithdrawing $10 by check (first check)"
#   new_bal = my_checking4.withdraw_using_check(10)
#   puts "The balance is now: $%.2f" % new_bal
#
# end
#
# puts "\n\nConfirm appropriate overdraft behavior for both types of withdrawal"
#
# my_checking5 = Bank::CheckingAccount.new(144070, 20.0, Time.now)
# puts my_checking5
#
# puts "\nWithdrawing $10 by check"
# new_bal = my_checking5.withdraw_using_check(22.0)
# puts "The balance is now: $%.2f" % new_bal
#
# puts "\nWithdrawing $2 by NON-check"
# new_bal = my_checking5.withdraw(2.0)
# puts "The balance is now: $%.2f" % new_bal
#
# puts "\nWithdrawing $2 by check"
# new_bal = my_checking5.withdraw_using_check(2.0)
# puts "The balance is now: $%.2f" % new_bal



# stored_accounts = Bank::Account.all
#
# stored_accounts.each do |account|
#   puts account
# end
#
# puts "\nAccount with ID 1217:"
# puts Bank::Account.find(1217)



# stored_owners = Bank::Owner.all
#
# stored_owners.each do |owner|
#   puts owner
# end
#
# puts "\nOwner with ID 22:"
# puts Bank::Owner.find(22)
#
# puts "\nOwner with ID 16:"
# puts Bank::Owner.find(16)



# stored_owners = Bank::Owner.all
#
# stored_owners.each do |owner|
#   puts owner
#   puts "Account(s): " + owner.account_IDs.to_s
#   puts "\n\n"
# end

# stored_accounts = Bank::Account.all
#
# stored_accounts.each do |account|
#   puts account
#   owner = Bank::Owner.find(account.owners[0])
#   puts "Owned by " + owner.name[:first].to_s + " " + owner.name[:last] + "\n\n"
# end


# puts "WELCOME TO BANK OF CAT"
# puts "\n"
#
# first = ""
#
# while (true)
#
#   print "Please enter your banking ID: "
#   my_id = gets.chomp.strip
#
#   begin
#     owner = Bank::Owner.find(Integer(my_id))
#
#     if owner == nil
#       puts "Sorry, that ID is not in our system. Please try again!"
#     else
#       puts "Welcome, #{owner.name[:first]} #{owner.name[:last]}!"
#
#       my_account = nil
#
#       if owner.account_IDs.length == 1
#
#         my_account_ID = owner.account_IDs[0]
#         my_account = Bank::Account.find(my_account_ID)
#
#       else
#
#         found = false
#
#         while (!found)
#
#           puts "Which account would you like to access?"
#
#           owner.account_IDs.each do |id_num|
#             puts "#{id_num}"
#           end
#
#           print "Please enter the number of the desired account: "
#           input = gets.chomp.strip
#
#           begin
#             if owner.account_IDs.include?(Integer(input))
#               my_account = Bank::Account.find(Integer(input))
#               found = true
#             else
#               puts "Sorry, I didn't get that, please try again!"
#             end
#           rescue ArgumentError
#             puts "Sorry, I didn't get that, please try again!"
#           end
#
#         end
#
#       end
#
#       while (true)
#
#         puts "\nWhat would you like to do next?"
#         puts "Make a deposit -- enter 1"
#         puts "Make a withdrawal -- enter 2"
#         puts "Check balance -- enter 3"
#         puts "Quit -- enter Q"
#         print "Choice: "
#
#         choice = gets.chomp.strip.downcase
#
#         case choice
#
#         when "1"
#           begin
#             print "How much would you like to deposit? $"
#             deposit_amount = Float(gets.chomp.strip)
#             puts "Thank you! Your new balance is: $%.2f" % my_account.deposit(deposit_amount)
#           rescue ArgumentError
#             puts "Sorry, I didn't get that! Please try again."
#           end
#         when "2"
#           print "How much would you like to withdraw? $"
#           withdrawal_amount = Float(gets.chomp.strip)
#           puts "Your balance is: $%.2f" % my_account.withdraw(withdrawal_amount)
#         when "3"
#           puts "Your balance is: $%.2f" % my_account.balance
#         when "q"
#           puts "Goodbye! Thank you for banking with BANK OF CAT!"
#           exit
#         else
#           puts "Sorry, I didn't get that, please try again!"
#         end
#
#       end
#
#     end
#   rescue ArgumentError
#     puts "Sorry, I didn't get that. Please try again!"
#   end
#
# end

# while (true)
#
#   puts "What would you like to do next?"
#   puts "Make a deposit -- enter 1"
#   puts "Make a withdrawal -- enter 2"
#   puts "Check balance -- enter 3"
#   puts "Quit -- enter Q"
#   print "Choice: "
#
#   choice = gets.chomp.strip.downcase
#
#   case choice
#
#   when "1"
#     begin
#       print "How much would you like to deposit? $"
#       deposit_amount = Float(gets.chomp.strip)
#       puts "Thank you! Your new balance is: $%.2f" % my_account.deposit(deposit_amount)
#     rescue ArgumentError
#       puts "Sorry, I didn't get that! Please try again."
#     end
#   when "2"
#     print "How much would you like to withdraw? $"
#     withdrawal_amount = Float(gets.chomp.strip)
#     puts "Your balance is: $%.2f" % my_account.withdraw(withdrawal_amount)
#   when "3"
#     puts "Your balance is: $%.2f" % my_account.balance
#   when "q"
#     puts "Goodbye! Thank you for banking with BANK OF CAT!"
#     exit
#   else
#     puts "Sorry, I didn't get that, please try again!"
#   end
#
# end
