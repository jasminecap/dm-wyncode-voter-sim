# Don Morehouse
require './prompters'
module TextFormatting
  SPACE = ' '
  def capitalize_words_in(string)
    # convert string to string, split,downcase and then capitalize each word
    # accepts symbols
    if string.nil?
      raise "String is nil."
    end
    string.to_s.split(SPACE).map do |token|
      token.downcase!
      token.capitalize
    end.join(SPACE)
  end
end

module HashHandler
  include TextFormatting

  def get_name_from(options)
    # order matters here, update person name takes precedence
    options[:update_person_name_menu] || options[:person_name_menu]
  end

  def set_name(person_name)
    @name = capitalize_words_in(person_name)
  end

  def get_politics(options, politics_menu, key)
    # reverse lookup
    # i.e. 'r' returns "Republican"
    politics_menu = politics_menu[:options]
    key = options[key]
    return politics_menu[key]
  end

  def update_with(options, politics_menu, key)
    # used in the context of initialize, 
    # not updating at user request
    person_name = get_name_from(options)
    set_name(person_name)
    if @name.empty?
      raise "empty name"
    end
    value = get_politics(options, politics_menu, key)
    unless value
      raise "value is undefined."
    end
    value
  end
end

class Person
  include TextFormatting
  include HashHandler

  attr_accessor :name, :my_politics
  attr_reader :prompts

  def initialize(name)
    @name = capitalize_words_in(name)
  end

  def update(answers, politics_menu, politics, world)
    # this is called when a user updates an instance
    my_people_name = self.class.to_s.downcase + 's'  # calculate instance varaible name
    my_people = world.instance_variable_get('@' + my_people_name)
    # check world for existence of person with same name and type
    # fails if world.edit check not done 
    if (my_people.include? self) && !(world.edit)
      puts
      puts "#{@name} already exists in #{my_people_name}"
      return self.my_politics
    end
    message = "Updating #{@name}. . . "
    Messages::success(message)
    new_name = get_name_from(answers)
    new_politics = get_politics(answers, politics_menu, politics)

    @name = capitalize_words_in(new_name)
    @my_politics = new_politics
    message = "#{@name} updated: #{new_name}, #{new_politics}."
    puts Messages::success(message)
  end
end


class Politician < Person
  attr_accessor :party

  def initialize(name=nil, options={})
    if name != nil
      super(name)
    end
    unless options.empty?
      @party = update_with(
        options, 
        Prompts::party_politician_menu, 
        :party_politician_menu
      )
      @my_politics = @party
    end
  end

  def update(answers, world)
    self.party = super(
      answers, 
      Prompts::update_party_politician_menu,
      :update_party_politician_menu,
      world
    )
  end
end

class Voter < Person
  attr_accessor :politics

  def initialize(name, options = {})
    if name != nil
      super(name)
    end
    unless options.empty?
      @politics = update_with(
        options, 
        Prompts::politics_voter_menu, 
        :politics_voter_menu
    )
      @my_politics = @politics
    end
  end

  def update(answers, world)
    self.politics = super(
      answers, 
      Prompts::update_politics_voter_menu, 
      :update_politics_voter_menu,
      world
    )
  end

end
