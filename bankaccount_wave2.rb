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

      linker.each do |link|
          target_account = Bank::Account.find(Integer(link[0]))
          target_owner = Bank::Owner.find(Integer(link[1]))
          target_account.add_owner(Integer(link[1]))
          target_owner.add_account(Integer(link[0]))
      end

    end

  end

  class Owner

    attr_reader :id, :name, :address, :account_IDs

    # The owner hash contains two smaller hashes. The hash accessed by :name
    # has sub-keys :first, :middle, and :last. The hash accessed by :address
    # has sub-keys :street1, :street2, :city, :state, :country, and :zip. Not
    # every field will be provided for every owner. The birthdate is just a
    # single Time object.

    @@all_owners = []

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

    # Find the owner that matches the given ID

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

    # Associate the provided account ID with this owner

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

  # Information about a bank account. Provides methods to allow transactions.

  class Account

    attr_reader :balance, :owners, :id, :creation_date

    @@all_accounts = []

    # Initialize account with user input

    def initialize(account_ID, account_initial_balance, date_of_creation, account_owner = nil)

      @id = account_ID
      @owners = [account_owner]
      @creation_date = date_of_creation

      # Negative balance is a no-go

      if account_initial_balance >= 0
        @balance = Float(account_initial_balance)
      else
        raise ArgumentError
      end

    end

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

    # def list_owners
    #
    #   owner_list = ""
    #
    #   if has_owner
    #
    #     counter = 1
    #
    #     @owners.each do |owner|
    #       owner_list = owner_list + "#{owner.name[:first]} #{owner.name[:middle]} #{owner.name[:last]}\n"
    #       counter += 1
    #     end
    #
    #   else
    #
    #     owner_list = "This account has no owner."
    #
    #   end
    #
    #   return owner_list
    #
    # end

    def to_s
      return "ID: " + @id.to_s + ", Balance: $%.2f" % @balance + ", Date of creation: " + @creation_date.to_s
    end

    private

        # Check if the account has an owner

    def has_owner
      if @owners[0] != nil
        return true
      else
        return false
      end
    end


  end

end

Bank::Account.read_accounts("./support/accounts.csv")

# stored_accounts = Bank::Account.all
#
# stored_accounts.each do |account|
#   puts account
# end
#
# puts "\nAccount with ID 1217:"
# puts Bank::Account.find(1217)

Bank::Owner.read_owners("./support/owners.csv")

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

Bank::AccountLinker.read_account_owner_associations("./support/account_owners.csv")

# stored_owners = Bank::Owner.all
#
# stored_owners.each do |owner|
#   puts owner
#   puts "Account(s): " + owner.account_IDs.to_s
#   puts "\n\n"
# end

stored_accounts = Bank::Account.all

stored_accounts.each do |account|
  puts account
  owner = Bank::Owner.find(account.owners[0])
  puts "Owned by " + owner.name[:first].to_s + " " + owner.name[:last] + "\n\n"
end

# interfaces

# bank_of_cat_register = Bank::Register.new # Register holds account IDs for all accounts in bank
#
# puts "WELCOME TO THE BANK OF CAT"
# puts "\n"
# puts "Here, you can create an account."
# puts "You will be prompted for various pieces of info to create your account."
# puts "\n"
#
# first = ""
#
# while (true)
#
#   print "Please enter your first name: "
#   first = gets.chomp.strip
#
#   if first == "" || first == " "
#     puts "Please enter a valid name."
#   else
#     break
#   end
#
# end
#
# print "Please enter your middle name: "
#
# middle = gets.chomp.strip
#
# last = ""
#
# while (true)
#
#   print "Please enter your last name: "
#   last = gets.chomp.strip
#
#   if last == "" || last == " "
#     puts "Please enter a valid name."
#   else
#     break
#   end
#
# end
#
# street1 = ""
#
# while (true)
#
#   print "Please enter your street address (line 1): "
#   street1 = gets.chomp.strip
#
#   if street1 == "" || street1 == " "
#     puts "Please enter a valid street address. Example: 123 Pleasant Dr."
#   else
#     break
#   end
#
# end
#
# print "Please enter your street address (line 2, if needed): "
#
# street2 = gets.chomp.strip
#
# city = ""
#
# while (true)
#
#   print "Please enter your city: "
#   city = gets.chomp.strip
#
#   if city == "" || city == " "
#     puts "Please enter a valid street address. Example: 123 Pleasant Dr."
#   else
#     break
#   end
#
# end
#
# state = ""
#
# while (true)
#
#   print "Please enter your state or province: "
#   state = gets.chomp.strip
#
#   if state == "" || state == " "
#     puts "Please enter a valid state. Example: WA"
#   else
#     break
#   end
#
# end
#
# country = ""
#
# while (true)
#
#   print "Please enter your country: "
#   country = gets.chomp.strip
#
#   if country == "" || country == " "
#     puts "Please enter a valid country. Example: USA"
#   else
#     break
#   end
#
# end
#
# zip = ""
#
# while (true)
#
#   print "Please enter your five-digit zip code: "
#   zip = gets.chomp.strip
#
#   begin
#
#     Integer(zip)
#
#     if zip.length == 5
#       break
#     else
#       puts "Please enter a valid 5-digit zip code. Example: 98006"
#     end
#
#   rescue ArgumentError
#     puts "Please enter a valid 5-digit zip code. Example: 98006"
#   end
#
# end
#
# while (true)
#
#   print "Please enter your birthdate (MM-DD-YYYY): "
#
#   full_date = gets.chomp.strip.split("-")
#   month = full_date[0]
#   day = full_date[1]
#   year = full_date[2]
#
#   begin
#
#     Time.new(year, month, day)
#     break
#
#   rescue ArgumentError, TypeError
#
#     puts "Sorry, I couldn't parse that date. Please try again! Example: 01-16-1986"
#
#   end
#
# end
#
#
# user = Bank::Owner.new({name: {first: first, middle: middle, last: last}, address: {street1: street1, street2: street2, city: city, state: state, country: country, zip: zip}, birthdate: Time.new(year, month, day)})
#
# #puts user
#
# account_number = nil
#
# while (true)
#
#   account_number = Random.rand(1..100000000)
#
#   if bank_of_cat_register.include?(account_number) == false
#     break
#   end
#
# end
#
# initial_deposit = 0.0
#
# while (true)
#
#   print "Please enter the amount you would initially like to deposit: $"
#
#   begin
#
#     initial_deposit = Float(gets.chomp.strip)
#     my_account = Bank::Account.new(account_number, initial_deposit, user)
#     break
#
#   rescue ArgumentError
#
#     puts "Please enter a valid, non-negative number as your initial deposit."
#
#   end
#
# end
#
# puts "\nThank you for activating your new account with BANK OF CAT!"
# puts "Your account information is:\n\n"
#
# puts "Owner: " + my_account.list_owners.to_s
#
# puts "Balance: $%.2f" % my_account.balance
#
# puts "Account ID: " + my_account.id.to_s
#
# puts "\n"
#
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





#Testing

# bucky_customer = Bank::Owner.new({name: {first: "Bucky", middle: "the", last: "Cat"}, address: {street1: "123 Oak Grove", street2: "Apt. 4H", city: "Anytown", state: "WA", country: "United States", zip: "00000"}, birthdate: Time.new(2005, 10, 31)})
# puts bucky_customer.name[:first]
# puts bucky_customer.address[:street2]
#
# puts bucky_customer

# my_account = Bank::Account.new("124023053", 235.27, bucky_customer)
#
# puts "Balance is: $#{my_account.balance}"
#
# my_withdrawal = 250.0
#
# puts "Withdrew $#{my_withdrawal}. New balance is $#{my_account.withdraw(my_withdrawal)}."
#
# my_deposit = 100.0
#
# puts "Deposited $#{my_deposit}. New balance is $#{my_account.deposit(my_deposit)}."
#
# #puts "Owner of this account is #{my_account.owner.name[:first]} #{my_account.owner.name[:middle]} #{my_account.owner.name[:last]}"
#
# satchel = Bank::Owner.new({name: {first: "Satchel", middle: "the", last: "Dog"}, address: {street1: "123 Oak Grove", street2: "Apt. 4H", city: "Anytown", state: "WA", country: "United States", zip: "00000"}, birthdate: Time.new(2005, 10, 31)})
#
# my_account.add_owner(satchel)
#
# counter = 1
#
# my_account.owners.each do |owner|
#   puts "Owner #{counter} of this account: #{owner.name[:first]} #{owner.name[:middle]} #{owner.name[:last]}"
#   counter += 1
# end
#
# account2 = Bank::Account.new("124113053", 100.35)
#
# rob = Bank::Owner.new({name: {first: "Rob", middle: "the", last: "Human"}, address: {street1: "123 Oak Grove", street2: "Apt. 4H", city: "Anytown", state: "WA", country: "United States", zip: "00000"}, birthdate: Time.new(2005, 10, 31)})
#
# puts account2.list_owners + "\n\n"
#
# account2.add_owner(rob)
#
# puts account2.list_owners + "\n\n"
#
# account2.add_owner(satchel)
#
# puts account2.list_owners + "\n\n"
#
# account2.add_owner(bucky_customer)
#
# puts account2.list_owners + "\n\n"
