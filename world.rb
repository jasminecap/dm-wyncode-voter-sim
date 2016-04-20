# Don Morehouse
require './prompters'
require './persons'

KEYS = [
  :main_menu,
  :create_menu,
  :list_menu,
  :person_name_menu,
  :update_menu,
  :update_person_name_menu,
  :delete_menu,
  :party_politician_menu,
  :update_party_politician_menu,
  :politics_voter_menu,
  :update_politics_voter_menu,
]
MENU_CLASSES = [
    MainMenuPrompter,
    CreateMenuPrompter,
    ListMenuPrompter,
    PersonNamePrompter,
    UpdateMenuPrompter,
    UpdatePersonNamePrompter,
    DeleteMenuPrompter,
    PoliticianPartyPrompter,
    UpdatePoliticianPartyPrompter,
    VoterPoliticsPrompter,
    UpdateVoterPoliticsPrompter,
]

class WorldUserInterface
  attr_accessor(
    :menus, 
    :answers, 
    :politicians, 
    :voters, 
    :people,
    :edit, 
    :person_to_edit
  )

  def initialize
    @answers = {}
    @menus = {}
    @politicians = []
    @voters = [] 
    @people = [@politicians, @voters]
    @edit = false
    @person_to_edit = nil
    # fill @menus with Prompter instances
    MENU_CLASSES.zip(KEYS).each do |menu_prompter, key|
      @menus[key] = menu_prompter.new
    end
  end

  def try_exit_gracefully(answer)
    # prevents all that ugly output on exit with control-C
    def _exit
      puts
      message = "Exiting now. Ciao!"
      puts Messages::colorize(message, :yellow, :black)
      exit
    end
    case true
    when answer == 'x' # exit on x input
      _exit
    when answer.class == Interrupt
      _exit
    else
      return answer
    end
  end

  def wait_for_answer(menu_name)
    menu = @menus[menu_name]
    answer_is_valid = nil
    until answer_is_valid  # keep looping until a valid answer
      if menu
        if menu.is_displayer == true  # then display 
          display_people
          menu = @menus[:main_menu]
        end
        menu.display_menu  # prompt question displayed
        begin
          answer = gets.chomp.downcase
          puts CLEAR
          try_exit_gracefully(answer)
        rescue Interrupt => e  # capture keyboard interrupt
          try_exit_gracefully(e)
        end
        # menu instance is responsible for validating input
        answer_is_valid = menu.validate(answer)
      else # display the default menu
        wait_for_answer :main_menu
      end
    end
    process(answer, menu_name, menu)
  end

  def process(answer, menu_name, menu)
    answer = answer.upcase.to_sym
    @answers[menu_name] = answer # lookup prompting menu in answers which is user input
    # each menu instance has as next_menu method that processes
    # info and returns the key for the next prompter
    next_menu = menu.next_menu(answer, @answers, self)
    # display a list of people after every update and delete
    if [:update_menu, :delete_menu].include? next_menu
      display_people
    end
    # world set to edit mode so process the edit
    if @edit == true  # capture answers for an update
        edit_entry next_menu
    end
    if next_menu  # prompt for next input
        wait_for_answer next_menu
    end
    
  end

  def edit_entry(next_menu)
    @person_to_edit.update(@answers, self)
    if next_menu == :list_menu  # finished with update cycle
      @edit = false  
      @answers = {}
    end
    wait_for_answer next_menu  # returns to next menu after prompt
  end

  def person_exists_in(answers, person_type_collection)
    # person_type_collection is nil on update 
    person_type_collection.any? do |person|
      person.name.downcase == answers[:person_name_menu].to_s.downcase
    end
  end

  def is_empty?
    people = @people.flatten
    people.empty? ? true : false
  end

  def display_people

    def black_on_white(message)
      Messages::colorize(message, :white, :black)
    end

    def print_seprarater(message)
      line = "*" * 79
      2.times { puts }
      puts black_on_white(message)
      puts black_on_white(line)
    end
    puts CLEAR
    [@politicians, @voters].zip(['politician', 'voter']) do |list, key|
      unless list.empty?
        print_seprarater(black_on_white("Here is a list of #{key}s:"))
        list.each do |person|
          puts black_on_white("#{key.capitalize}: #{person.name}, #{person.my_politics.capitalize}")
        end
      else
        print_seprarater(black_on_white("#{key.capitalize} list is empty."))
      end
    end
    
  end
end
