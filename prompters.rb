# Don Morehouse
require './persons'

SPACE = " "
CLEAR = `tput clear`
module Prompts
  def self.main_menu
    {
      prompt: "What would you like to do?\n#{BG_YELLOW}(X to exit)#{NORMAL}",
      options: {
        C: "create",
        L: "list",
        U: "update",
        D: "delete"
      },
    }
  end

  def self.no_people_message
    Messages::colorize("No people exist.", :red, :black)
  end 

  def self.create_menu
    {
      prompt: "What would you like to create?",
      options: {
        P: "politician",
        V: "voter"
      }
    }

  end

  def self.list_menu
    {
      prompt: nil,
      options: nil,
    }
  end

  def self.update_menu
    {
      prompt: "Who would you like to update?",
      options: nil
    }
  end

  def self.delete_menu
    {
      prompt: "Who would you like to delete?",
      options: nil,
    }
  end

  def self.person_name_menu
    {
      prompt: "Name?",
      options: nil
    }
  end
  
  def self.update_person_name_menu
    {
      prompt: "New name?",
      options: nil
    }
  end

  def self.party_politician_menu
    {
      prompt: "Party?", 
      options: {
        D: "democrat",
        R: "republican",
      }
    }
  end
  
  def self.update_party_politician_menu
    old = self.party_politician_menu
    {
      prompt: "New party?",
      options: old[:options]
    }
  end

  def self.politics_voter_menu
    {
      prompt: "Politics?",
      options: {
        L: "liberal",
        C: "conservative",
        T: "tea party",
        S: "socialist",
        N: "neutral",
      } 
    }
  end
  
  def self.update_politics_voter_menu
    old = self.politics_voter_menu
    {
      prompt: "New politics?",
      options: old[:options],
    }
  end
end

BG_BLACK = `tput setab 0`
BG_BLUE = `tput setab 4`
BG_GREEN = `tput setab 2`
BG_RED = `tput setab 1`
BG_WHITE = `tput setab 7 `
BG_YELLOW = `tput setab 3 `
BLACK = `tput setaf 0`
BLUE = `tput setaf 4`
GREEN = `tput setaf 2`
NORMAL = `tput sgr0`
RED = `tput setaf 1`
WHITE = `tput setaf 7`
YELLOW = `tput setaf 3`

module ScreenColors
  class ScreenColors
    def self.screen_colors
      {
        black: {
          background: BG_BLACK,
          foreground: BLACK,
        },
        blue: {
          background: BG_BLUE,
          foreground: BLUE,
        },
        green: {
          background: BG_GREEN,
          foreground: GREEN,
        },
        red: {
          background: BG_RED,
          foreground: RED,
        },
        white: {
          background: BG_WHITE,
          foreground: WHITE,
        },
        yellow: {
          background: BG_YELLOW,
          foreground: YELLOW,
        },
      }
    end
  end
end

module Messages
  include ScreenColors

  def self.colorize(string, bg_color, fg_color)
    screen_colors = ScreenColors.screen_colors
    bg_color = screen_colors[bg_color][:background]
    fg_color = screen_colors[fg_color][:foreground]
    "#{bg_color}#{fg_color}#{string}#{NORMAL}"
  end

  def self.warning(string)
    self.colorize(string, :yellow, :black)
  end

  def self.critical(string)
    self.colorize(string, :red, :black)
  end
  def self.success(string)
    self.colorize(string, :green, :black)
  end

  def self.not_valid
      message = "Not a valid response."
      puts self.colorize(message, :red, :black)
  end

end

module CommonNextMenus
  def get_person_type_string_from(world, answers)
    lookup_person_type = {
      update_politics_voter_menu: :V,
      update_party_politician_menu: :P,
    }
    # gives the person type, V or P, update is missing a create_menu
    # and there are two different menu types for voters and politicians
    # This would not scale well.
    person_type_key = answers[:create_menu]\
      || lookup_person_type[:update_politics_voter_menu]\
      || lookup_person_type[:update_party_politician_menu]
    # reverse lookup what v or p point to, 
    # prepend with @ and make plural to access attr
    [
      '@',
      Prompts::create_menu[:options][person_type_key],
      's',
    ].join
  end

  def get_persons_by_type_from(world, answers)
    person_type =get_person_type_string_from(world, answers)
    world.instance_variable_get(person_type)
  end

  def person_politics_next_menu(answer, answers, world)
    # Having to do this would have been avoided if I
    # had modeled politicians and voters first as "ElectionParticipants"
    # and then had Voter and Politician inherit from that
    # Too late to turn back now: Done is better than perfect
    # I learned something from this bit of mess.
    # returns voters or politicians depending on answers
    persons = get_persons_by_type_from(world, answers)
    persons_collection_name = get_person_type_string_from(world, answers)
    # remove the @
    persons_name_sans_at_symbol = persons_collection_name.gsub(/^@/, '')
    #remove the s
    class_type_name = persons_name_sans_at_symbol\
      .gsub(/s{1}$/, '')\
      .capitalize

    if world.person_exists_in(answers, persons) == false
      if world.edit == true  # prevents adding update as a new record
        return answers
      end
      # create the object from Object using calculated name, Voter or Politician
      person_class = Object.const_get(class_type_name)
      persons_collection = world.instance_variable_get(persons_collection_name)
      # new person instance created here and added to voters or politicians
      persons_collection << person_class.new(nil, answers)
      new_person = persons_collection.last
      message = [
        "Created #{new_person.name},",
        "#{new_person.class.to_s.downcase},",
        "#{new_person.my_politics.capitalize}",
      ].join(SPACE)
      puts Messages::success(message)
    else
      puts
      message = [
        "#{answers[:person_name_menu].to_s} ",
        "already exists in the #{class_type_name.downcase} list. ",
        "You may choose to update.",
      ].join(SPACE)
      puts Messages::warning(message)
    end
    :main_menu
  end

  def politician_party_next_menu(answer, answers, world)
    person_politics_next_menu(answer, answers, world)
  end

  def voter_politics_next_menu(answer, answers, world)
    person_politics_next_menu(answer, answers, world)
  end

  def calculate_next(answer, answers, world, next_menu)
    if world.edit == false
      person_type = Prompts::create_menu
      person_type = person_type[:options][answers[:create_menu]].to_sym
      next_menu[person_type]
    elsif world.edit == true
      message = "Begin edit..."
      puts Messages::success(message)
      return next_menu[world.person_to_edit.class]
    end
  end
end

module SearchHelpers
  def get_people_to_edit(world, answer, answers)
    if world.people.flatten.empty?
      message = "No people have yet been created."
      Messages::warning(message)
      return nil
    end
    person_of_interest = answers[:update_menu] || answers[:delete_menu]
    cap_person_name = capitalize_words_in(person_of_interest)
    message = "Starting search for #{cap_person_name}. . ."
    puts Messages::success(message)
    # answers has person keyed by originating menu type
    matches = {politicians: nil, voters: nil}
    world.people.each do |people_list|
      person_to_edit = nil
      person_type = nil
      # comma unpacks single item from array, 
      # assumes uncontaminated data! (one value)
      person_to_edit, = people_list.select do |person|
        person_name = person.name.to_s.downcase
        search_criteria = person_of_interest.to_s.downcase
        person_type = (person.class.to_s.downcase + 's').to_sym
        person_name == search_criteria
      end
      matches[person_type] = person_to_edit
    end
      # convert to names for printing
    matches.each do |(_person_type, person)|
      unless person.nil?
        message = "#{person.name} exists in #{_person_type}."
        puts Messages::warning(message)
      end
    return matches
    end
  end

end

class Prompter
  include(
    TextFormatting,
    Prompts,
    HashHandler,
    CommonNextMenus,
    SearchHelpers,
  )
  attr_accessor :menu_type, :is_displayer
  def initialize
    @is_displayer = false
  end

  def ask
    puts
    current_prompt = get_prompt
    message = Messages::colorize(current_prompt, :green, :black)
    puts "#{message}"
  end

  def print_options
    menu = Prompts.method(@menu_type).call
    message = Messages::colorize(format_options(menu[:options]), :blue, :white)
    puts message
  end

  def display_menu
    ask
    print_options
  end

  def validate(input)
    menu = Prompts.method(@menu_type).call
    begin
      result = menu[:options].key? input.upcase.to_sym
      unless result
        puts Messages::not_valid
      end
      result
    rescue
      puts Messages::not_valid
      false
    end
  end

  def validate_keyboard(input)
    # override because free text is entered rather than a choice
    begin
      tokens = input.split(' ')
      result = tokens.size == 2
      unless result
        puts Messages::not_valid
        puts Messages::colorize("Only two words allowed.", :red, :black)
      end
      result
    rescue
      puts Messages::not_valid
      false
    end
  end

  private
  def get_prompt
    menu = Prompts.method(@menu_type).call
    return menu[:prompt]
  end

  def format_options(options)
    if options
      options = options.map do |(key, value)|
        prefix = "(#{key.to_s.upcase})"  # surround option with ()
        suffix = "#{value[1..-1]}"
        [prefix, suffix].join
      end.join(SPACE)
    end
  end

end

class MainMenuPrompter < Prompter
  def initialize
    @menu_type = :main_menu
  end

  def next_menu(answer, answers, world)
    # if there are no people, choosing U or D
    # should return to main menu
    if world.is_empty? && ([:U, :D].include? answers[:main_menu])
      puts Prompts::no_people_message
      return :main_menu
    end
    {
      C: :create_menu,
      L: :list_menu,
      U: :update_menu,
      D: :delete_menu,
    }[answer]
  end

end

class CreateMenuPrompter < Prompter
  def initialize
    @menu_type = :create_menu
  end

  def next_menu answer, answers, world
    :person_name_menu
  end

end

class ListMenuPrompter < Prompter

  def initialize
    @menu_type = :list_menu
    @is_displayer = true
  end

end

class PersonNamePrompter < Prompter
  def initialize
    @menu_type = :person_name_menu
  end

  def validate(input)
    validate_keyboard(input)
  end


  def next_menu(answer, answers, world)
    next_menu = {
      politician: :party_politician_menu,
      voter: :politics_voter_menu,
      Politician => :party_politician_menu,
      Voter => :politics_voter_menu,
    }
    calculate_next(answer, answers, world, next_menu)
  end

end

class UpdatePersonNamePrompter < Prompter
  def initialize
    @menu_type = :update_person_name_menu
  end
  
  def validate(input)
    validate_keyboard(input)
  end
  
  def next_menu(answer, answers, world)
    next_menu = {
      politician: :update_party_politician_menu,
      voter: :update_politics_voter_menu,
      Politician => :update_party_politician_menu,
      Voter => :update_politics_voter_menu,
    }
    calculate_next(answer, answers, world, next_menu)
  end

end


class PoliticianPartyPrompter < Prompter
  include CommonNextMenus
  
  def initialize
    @menu_type = :party_politician_menu
  end

  def next_menu(answer, answers, world)
    politician_party_next_menu(answer, answers, world)
  end
end

class UpdatePoliticianPartyPrompter < Prompter
  include CommonNextMenus
  
  def initialize
    @menu_type = :update_party_politician_menu
  end
  
  def next_menu(answer, answers, world)
    politician_party_next_menu(answer, answers, world)
  end
end

class UpdateVoterPoliticsPrompter < Prompter
  include CommonNextMenus
  
  def initialize
    @menu_type = :update_politics_voter_menu
  end
  
  def next_menu(answer, answers, world)
    voter_politics_next_menu(answer, answers, world)
  end
end

class VoterPoliticsPrompter < Prompter
  include CommonNextMenus
  
  def initialize
    @menu_type = :politics_voter_menu
  end

  def next_menu(answer, answers, world)
    voter_politics_next_menu(answer, answers, world)
  end
end


class UpdateMenuPrompter < Prompter
  def initialize
    @menu_type = :update_menu
  end

  def validate(input)
    validate_keyboard(input)
  end

  def next_menu(answer, answers, world)
    if world.is_empty?
      puts Prompts::no_people_message
      return :main_menu  # takes us back to main menu
    else
      people_to_edit = get_people_to_edit(world, answer, answers)
      world.edit = true  # forces return from world.wait_for_answer
      # check for duplicates and then ask which one to edit
      if people_to_edit.all? do |(_, person)|
          person.nil? == false
        end

        # spot for a prompter instance! TODO
        message = [
          "Which type of person do you want to edit?",
          "(P)olitican or (V)oter?",
        ].join("\n")
        puts Messages::success(message)
        choice = gets.chomp.upcase.to_sym
        choice = {P: :politicians, V: :voters}[choice]
        person_to_edit = people_to_edit[choice] 

      else
        person_to_edit, = people_to_edit.select do |_, person|
          person.nil? == false
        end
        person_to_edit = person_to_edit[:politicians] || person_to_edit[:voters]
      end
      world.person_to_edit = person_to_edit
      answers = world.wait_for_answer :update_person_name_menu
    end
  end

end

class DeleteMenuPrompter < Prompter
  def initialize
    @menu_type = :delete_menu
  end

  def validate(input)
    # override because free text is entered rather than a choice
    begin
      tokens = input.split(' ')
      tokens.size == 2
    rescue
      false
    end
  end

  def next_menu answer, answers, world
    people_to_edit = get_people_to_edit(world, answer, answers)
    if people_to_edit.nil? || people_to_edit.empty?
      message = "There are no people to delete."
      Messages::warning(message)
      world.wait_for_answer :main_menu
    end
    if people_to_edit.all? do |(_, person)|
        person.nil? == false
      end
      # spot for a prompter instance! TODO
      message = [
        "Which type of person do you want to edit?",
        "(P)olitiican or (V)oter?",
      ].join("\n")
      puts Messages::success(message)
      choice = gets.chomp.upcase.to_sym
      choice = {P: :politicians, V: :voters}[choice]
      person_to_edit = people_to_edit[choice] 

    else
      person_to_edit, = people_to_edit.select do |_, person|
        person.nil? == false
      end
      person_to_edit = person_to_edit[:politicians] || person_to_edit[:voters]
    end

    if person_to_edit.is_a? Person
      message = [
        "You are about to delete #{person_to_edit.name}",
        "the #{person_to_edit.class.to_s.downcase}.",
      ].join(SPACE)
      puts Messages::critical(message)
      confirmation = nil
      while !confirmation
        message = "Are you sure? Y/n"
        puts Messages::critical(message)
        entry = gets.chomp.downcase
        confirmation = ['y', 'n'].any? { |item| item == entry }
      end
      if entry == 'y'
        world.people.each do |people|  # find the person to edit
          people.each do |person|
            if person == person_to_edit
              message = "Deleting #{person.name}."
              Messages::critical(message)
              people.delete_at (people.index person)
            end
          end
        end
      elsif entry == 'n'
        message = "Not deleting #{person_to_edit.name}."
        puts Messages::warning(message)
        world.wait_for_answer :main_menu
      end
    else
      message = "Person not found."
      puts Messages::warning(message)
      world.wait_for_answer :main_menu  # return to default menu
    end
  end
end

