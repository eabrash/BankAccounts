# bankaccount_wave3.rb
#
# Represents a bank account. Reads in account data, owner data, and owner-account
# relationships from CSV files. Please note that this version utilizes an extended
# account CSV file ("account_types.csv") that includes the type of each account -
# it will not run correctly with the original "accounts.csv" file. Accounts may be
# SavingsAccount, CheckingAccount, or MoneyMarketAccount, each of which inherits
# from Account.

require "csv"

module Bank

  # Class holding basic information on owner of a bank account. This was made
  # in an effort to respect the "single responsiblity principle," since it did
  # not seem like this association behavior properly belonged to either Owner
  # or Account. This and other functionality might best reside in a Bank class
  # or some other, higher-level class.

  class AccountLinker

    def self.read_account_owner_associations(csv_file)

      linker = CSV.read(csv_file)

      # Associate account ID with owner and vice versa. Index 0 of link is the
      # account ID and index 1 of link is the owner ID. Owner objects keep a
      # list of their account IDs, and Account objects keep a list of their
      # owner IDs. An account may have multiple owners, as in a married couple,
      # and an owner may have multiple accounts, such as a checking and a savings.

      linker.each do |link|
          target_account = Bank::Account.find(Integer(link[0]))
          target_owner = Bank::Owner.find(Integer(link[1]))
          target_account.add_owner(Integer(link[1]))
          target_owner.add_account(Integer(link[0]))
      end

    end

  end

  # Class representing an account owner. An Owner object stores information about
  # the owner, as well as a list of the IDs of the accounts that owner has.

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
      @account_IDs = []       # This is an array because the same owner could have multiple accounts.
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

    # Find the Owner object that matches the given ID.

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

    # Associate the provided account ID with this owner. (Not used in current user
    # interface - leftover method from earlier implementation.)

    def add_account(account_ID)
      if @account_IDs[0] == nil
        @account_IDs = [account_ID]
      else
        @account_IDs << account_ID
      end
    end

    # Return a printable version of owner's name and address.

    def to_s
      return "#{@id}: #{@name[:first]} #{@name[:middle]} #{@name[:last]}\n#{@address[:street1]}\t #{@address[:street2]}\n#{@address[:city]}, #{@address[:state]} #{@address[:zip]}\t#{@address[:country]}\n\n"
    end

  end

  # Class representing a bank account. Provides methods to allow transactions.

  class Account

    attr_reader :balance, :owners, :id, :creation_date, :type

    @@all_accounts = []

    # Initialize account with account data input. An owner can optionally be provided
    # upon initialization, but this functionality is not used in the current version of
    # the program.

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      @id = account_ID
      @owners = [account_owner]
      @creation_date = date_of_creation
      @type = "account"

      # Negative starting balance produces an error

      if account_initial_balance >= 0
        @balance = Float(account_initial_balance)
      else
        raise ArgumentError
      end

    end

    # Read in information from a CSV and store it in the @@all_accounts class
    # variable. Money is stored as a Float in dollars. Will throw errors if
    # an account is below its minimum balance when read in.

    def self.read_accounts(csv_file)

      accounts = CSV.read(csv_file)

      accounts.each do |account|

        account_type = account[3]

        if account_type == "savings"
          @@all_accounts << Bank::SavingsAccount.new(Integer(account[0]), Float(account[1])/100.0, DateTime.parse(account[2]))
        elsif account_type == "checking"
          @@all_accounts << Bank::CheckingAccount.new(Integer(account[0]), Float(account[1])/100.0, DateTime.parse(account[2]))
        elsif account_type == "money market"
          @@all_accounts << Bank::MoneyMarketAccount.new(Integer(account[0]), Float(account[1])/100.0, DateTime.parse(account[2]))
        else
          @@all_accounts << Bank::Account.new(Integer(account[0]), Float(account[1])/100.0, DateTime.parse(account[2]))
        end

      end

    end

    # Write the final state of accounts to a CSV file. The output file can be
    # read as an input file in the future.

    def self.write_accounts(csv_file)

      output_csv = CSV.open(csv_file, "w")

      @@all_accounts.each do |account|
        output_csv << [account.id.to_s, (account.balance * 100).round.to_s, account.creation_date.to_s, account.type]
      end

    end

    # Return list of all Accounts that have been created.

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

      my_string = "ID: " + @id.to_s + ", Balance: $%.2f" % @balance + ", Date of creation: " + @creation_date.to_s + ", Type: " + @type + ", Owner(s): "

      # The section below tacks on a nicely formatted representation of owner's or owners'
      # names and IDs.

      if owners == nil || owners == [nil]
        my_string = my_string + "<none>"
      else
        counter = 0
        owners.each do |owner|
          if counter > 0
            my_string = my_string + ", "
          end
          my_string = my_string + Bank::Owner.find(owner).name[:first] + " " + Bank::Owner.find(owner).name[:last] + " (ID: " + owner.to_s + ")"
          counter += 1
        end
      end

      return my_string

    end

  end

  # Class used only as an "ancestor" for SavingsAccount and MoneyMarketAccount.
  # Defines the shared add_interest class so it doesn't have to be written
  # in two places (given that it is identical for SavingsAccount and
  # MoneyMarketAccount).

  class LongTermAccount < Bank::Account

    def add_interest(rate)

      interest = @balance * rate/100.0
      @balance += interest
      return interest

    end

  end

  # SavingsAccount inherits from Account. It has specific withdrawal fees not
  # present in the basic Account class and a minimum balance of $10, and it
  # also has a special method for adding interest.

  class SavingsAccount < Bank::LongTermAccount

    FEE = 2.0
    MIN_BAL = 10.0

    # Utilizes parent class' initialize method (via super) and adds additional_feature
    # assignments and checks.

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      super   # This is kind of sloppy to call here because it will still do the < 0 check and assign the balance
              # before throwing the error below if the balance is between $0 and $10

      @type = "savings"

      if account_initial_balance < MIN_BAL
        raise ArgumentError
      end

    end

    # Overrides parent method. This would probably be better refactored so that
    # the parent class method has a built-in fee (which is zero in the event
    # that a withdrawal does not incur a fee), making it possible to use the
    # parent method here with minimal or no modification rather than rewriting.

    def withdraw(amount_to_withdraw)

      if amount_to_withdraw <= @balance - MIN_BAL - FEE
        @balance -= amount_to_withdraw + FEE
      else
        puts "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + ". Remember, you must keep $%.2f" % MIN_BAL + " in your savings account at all times, and a $%.2f" % FEE + " fee is incurred for each withdrawal. No withdrawal was made."
      end

      return @balance

    end

  end

  # CheckingAccount class inherits from Account. It has a more complex process
  # for determining the fee charged upon withdrawal, with different protocols
  # for direct vs. check withdrawals and a limit of 3 free check withdrawals
  # before a fee is charged. The fee is always $1 for a direct withdrawal, and
  # it is $2 for a check withdrawal in excess of the three free check
  # withdrawals allowed per month.

  class CheckingAccount < Bank::Account

    NON_CHECK_WITHDRAWAL_FEE = 1.0
    CHECK_WITHDRAWAL_FEE = 2.0
    FREE_CHECKS_PER_MONTH = 3
    MAX_ALLOWABLE_OVERDRAFT = 10.0

    attr_reader :free_checks_available

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      super

      @type = "checking"
      @free_checks_available = FREE_CHECKS_PER_MONTH

    end

    # Overrides withdraw method of parent class. As mentioned in SavingsAccount,
    # there is probably a more efficient (less repetitive) way of doing this by
    # including a withdraw method with fees in the parent class.

    def withdraw(amount_to_withdraw)

      if amount_to_withdraw <= @balance - NON_CHECK_WITHDRAWAL_FEE
        @balance -= amount_to_withdraw + NON_CHECK_WITHDRAWAL_FEE
      else
        puts "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + " by direct withdrawal. Remember that a $%.2f" % NON_CHECK_WITHDRAWAL_FEE + " fee is incurred for each withdrawal. No withdrawal was made."
      end

      return @balance

    end

    # Distinct withdrawal method unique to CheckingAccount. Allows up to a $10
    # overdraft. $2 fee is charged per withdrawal when more than three check
    # withdrawals are made in a month.

    def withdraw_using_check(amount_to_withdraw)

      transaction_fee = 0.0

      if @free_checks_available <= 0
        transaction_fee = CHECK_WITHDRAWAL_FEE
      end

      if amount_to_withdraw <= @balance - transaction_fee + MAX_ALLOWABLE_OVERDRAFT

        @balance -= amount_to_withdraw + transaction_fee

        if @free_checks_available > 0
          @free_checks_available -= 1
        end

      else

        print "Sorry, your account balance is only $%.2f" % @balance + ", which is not enough for you to withdraw $%.2f" % amount_to_withdraw + ". Remember that you can only have a maximum overdraft of $-%.2f" % MAX_ALLOWABLE_OVERDRAFT + "."

        if transaction_fee == CHECK_WITHDRAWAL_FEE
          print " Also, a $%.2f" % CHECK_WITHDRAWAL_FEE + " fee would be charged, because you've already used up your #{FREE_CHECKS_PER_MONTH} free check withdrawals for this month."
        end

        print " No withdrawal was made.\n"

      end

      return @balance

    end

    # Reset number of free check withdrawal to the max per month (three).
    # We are now in a new month so the person has three more free check
    # withdrawals to use.

    def reset_checks
      @free_checks_available = FREE_CHECKS_PER_MONTH
    end

  end

  # MoneyMarketAccount inherits from Account. It has some unique features,
  # including a high minimum balance, a maximum number of transactions per
  # month, and a fee and account freeze imposed for dropping of the balance
  # below the minimum. MoneyMarketAccounts also accumulate interest, like
  # CheckingAccounts.

  class MoneyMarketAccount < Bank::LongTermAccount

    MAX_TRANSACTIONS = 6
    MIN_BAL = 10000.0
    BELOW_MINIMUM_FEE = 100.0

    attr_reader :transactions_remaining

    # Utilizes base class initialize method with additional conditions and
    # assignment statements.

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      super

      if account_initial_balance < MIN_BAL
        raise ArgumentError
      end

      @type = "money market"
      @transactions_remaining = MAX_TRANSACTIONS
      @frozen = false

    end

    # Overrides base class withdraw method. If base class method were improved
    # as described in previous sections (incorporating fee and minimum balance
    # as part of its general structure), this method could likely use much of
    # the base class functionality.

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

    # Overrides base class deposit method to allow for unique messages and
    # handling of transaction number and the frozen account case.

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

    # Reset number of transactons remaining to the maximum per month, as when
    #  we are entering a new month.

    def reset_transactions
      @transactions_remaining = MAX_TRANSACTIONS
    end

  end

end

# If a path is provided as a command line argument, the file indicated by the path
# is used as the source for the bank account data. Owner and owner-account association
# files are invariant because these features cannot be modified through the interface below.
# The source file only indicates the ID, balance, creation time, and type of each account,
# not the status of things like number of free check withdrawals or money market
# transactions remaining - these are all returned to default (full) values upon loading.
#
# How to use ARGV and gets.chomp in the same file:
# http://www.mkltesthead.com/2011/11/exercise-14-prompting-and-passing-learn.html

if ARGV.empty?
  Bank::Account.read_accounts("./support/accounts_types.csv")
else
  puts ARGV[0]
  Bank::Account.read_accounts(ARGV[0])
end

Bank::Owner.read_owners("./support/owners.csv")
Bank::AccountLinker.read_account_owner_associations("./support/account_owners.csv")

# Prints out accounts (for testing purposes only)

Bank::Account.all.each do |account|
  puts account
end

INTEREST = 0.25

# Main program loop. At present, the program interface allows existing customers to
# access their accounts and perform transactions. The customer must know his/her ID
# and the ID of the target account. The interface also allows an administrator to
# view all the accounts and increment time (indicating the passage of a month, which
# results in the compounding of interest and resetting of free check withdrawals and
# transactions for the month). The administrator also has the capacity to shut down
# the system and save the accounts and their current balances to a CSV file. This
# file can be read back in via the command line (or through copy-pasting into this
# file) to initialize the system with the same balances as when it shut down.
#
# The interface doesn't currently allow the creation of new accounts, addition or
# deletion of owners from an account or accounts from an owner, or transfer of
# account ownership.

while (true)

  puts "\nWELCOME TO BANK OF CAT"
  puts "\n"

  print "Please enter your banking ID: "
  my_id = STDIN.gets.chomp.strip

  # If user is actually admin...

  if my_id == "SUPER SECRET ADMIN"

    puts "CURRENT ACCOUNTS - BALANCE STATUS:\n"

    Bank::Account.all.each do |account|
      output = account.to_s

      if account.type == "checking"
        output = output + ", Number of check withdrawals remaining: #{account.free_checks_available}"
      elsif account.type == "money market"
        output = output + ", Number of transactions remaining: #{account.transactions_remaining}"
      end

      puts output

    end

    puts "\n"
    puts "Welcome to the SUPER SECRET ADMIN interface!"
    puts "The super secret admin can see account info, write account data to file, and control the passage of time.\n\n"

    done = false

    while (!done)

      puts "What would you like to do?\n\n"

      puts "1 - Register the passage of a month (add interest, reset transaction and check withdrawal limits)"
      puts "2 - Shut the system down and write core account stats to file"
      puts "3 - Exit the administrator interface and return to the main system"

      print "\nPlease enter the number of your choice --> "

      response = STDIN.gets.chomp.strip

      if response == "1"
        Bank::Account.all.each do |account|
          if account.type == "savings"
              account.add_interest(INTEREST)
          elsif account.type == "checking"
              account.reset_checks
          elsif account.type == "money market"
              account.reset_transactions
              account.add_interest(INTEREST)
          end
        end
        puts "Thank you! Interest has been added and check withdrawals and transactions have been reset."

        puts "\nCURRENT ACCOUNTS - BALANCE STATUS:\n"

        Bank::Account.all.each do |account|
          output = account.to_s

          if account.type == "checking"
            output = output + ", Number of check withdrawals remaining: #{account.free_checks_available}"
          elsif account.type == "money market"
            output = output + ", Number of transactions remaining: #{account.transactions_remaining}"
          end

          puts output

        end

        puts "\n"

      elsif response == "2"

        # Before exiting, write the updated state of the accounts to a CSV file

        puts "Writing to file..."
        Bank::Account.write_accounts("accounts_#{Time.now}.csv")
        puts "Shutting down..."
        exit

      elsif response == "3"

        puts "OK, see you next time!"
        done = true
        break

      else

        puts "\nSorry, I didn't get that. Please try again!\n\n"

      end
    end

  # If normal bank customer (not admin)...

  else

    begin
      owner = Bank::Owner.find(Integer(my_id))

      if owner == nil
        puts "Sorry, that ID is not in our system. Please try again!"
      else
        puts "Welcome, #{owner.name[:first]} #{owner.name[:last]}!"

        my_account = nil

        if owner.account_IDs.length == 1

          my_account_ID = owner.account_IDs[0]
          my_account = Bank::Account.find(my_account_ID)
          puts "Accessing your #{my_account.type} account with ID of #{my_account_ID}"

        else

          found = false

          while (!found)

            if owner.account_IDs.length != 0

              puts "Which account would you like to access?"

              owner.account_IDs.each do |id_num|
                puts "#{id_num}: #{Bank::Account.find(id_num).type}"
              end

              print "Please enter the number of the desired account: "
              input = STDIN.gets.chomp.strip

              begin
                if owner.account_IDs.include?(Integer(input))
                  my_account = Bank::Account.find(Integer(input))
                  found = true
                else
                  puts "Sorry, I didn't get that, please try again!"
                end
              rescue ArgumentError
                puts "Sorry, I didn't get that, please try again!"
              end
            else
              puts "Sorry, you do not have any accounts with us at the moment. Please consult your nearby BANK OF CAT to open a new account."
              break
            end
          end

        end



        while (found)

          puts "\nWhat would you like to do next?"
          puts "Check balance -- enter 1"
          puts "Make a deposit -- enter 2"

          if my_account.type == "checking"
            puts "Make a direct withdrawal -- enter 3"
            puts "Make a check withdrawal -- enter 4"
          else
            puts "Make a withdrawal -- enter 3"
          end

          puts "Quit -- enter Q"
          print "Choice: "

          choice = STDIN.gets.chomp.strip.downcase

          if choice == "1"
            puts "Your balance is: $%.2f" % my_account.balance
          elsif choice == "2"
            begin
              print "How much would you like to deposit? $"
              deposit_amount = Float(STDIN.gets.chomp.strip)
              puts "Thank you! Your new balance is: $%.2f" % my_account.deposit(deposit_amount)
            rescue ArgumentError
              puts "Sorry, I didn't get that! Please try again."
            end
          elsif choice == "3"
            print "How much would you like to withdraw? $"
            withdrawal_amount = Float(STDIN.gets.chomp.strip)
            puts "Your balance is: $%.2f" % my_account.withdraw(withdrawal_amount)
          elsif choice == "4" && my_account.type == "checking"
            print "How much would you like to withdraw by check? $"
            withdrawal_amount = Float(STDIN.gets.chomp.strip)
            puts "Your balance is: $%.2f" % my_account.withdraw_using_check(withdrawal_amount)
          elsif choice == "q"
            puts "Goodbye! Thank you for banking with BANK OF CAT!"
            break
          else
            puts "Sorry, I didn't get that, please try again!"
          end

        end

      end
    rescue ArgumentError
      puts "Sorry, I didn't get that. Please try again!"
    end
  end
end
