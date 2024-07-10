require "yaml"
class Hangman
  def initialize(_lives = 5)
    @word = generate_random_word.downcase
    @lives = 5
    @correct_guesses = []
    @incorrect_guesses = []
    fill_random_indexes # @word_progress
    @current_save = "temp.yaml"
  end

  def test
    @word = "punctuation"
    @lives = 5
    @correct_guesses = []
    @incorrect_guesses = []
    @word_progress = %w[p u _ _ _ _ _ _ _ _ _]
  end

  def generate_random_word
    File.open("words.txt", "r") do |file|
      words = file.readlines
      selected_word = ""
      selected_word = words.sample.chomp until selected_word.length.between?(5, 12)
      selected_word
    end
  end

  def fill_random_indexes
    counter = (@word.length / 3.0).round
    @word_progress = Array.new(@word.length, "_")
    until counter.zero?
      index = rand(0...@word.length)
      if @word_progress[index] == "_"
        @word_progress[index] = @word[index]
        counter -= 1
      end
    end
  end

  # assuming letter is not in correct_guesses or incorrect_guesses
  # if word has letter but no _ left and not in correct_guess , subtract life as its prefilled letters
  # eg: co_l, guess l should reduce life, but not o.
  def guess(letter)
    letter = letter.downcase
    return puts "Already guessed" if @correct_guesses.include?(letter) || @incorrect_guesses.include?(letter)

    letter_preset = !progress_changed?(letter)
    if letter_preset
      @incorrect_guesses << letter
      @lives -= 1
    else
      @correct_guesses << letter
    end
  end

  def progress_changed?(letter)
    return false unless @word.include?(letter)

    progress_made = false
    @word.each_char.with_index do |char, index|
      if @word_progress[index] == "_" && char == letter
        @word_progress[index] = letter
        progress_made = true
      end
    end
    progress_made
  end

  def display
    puts "word: #{@word_progress.join(' ')}"
    puts "lives: #{@lives}"
    puts "correct guesses: #{@correct_guesses.join(', ')}"
    puts "incorrect guesses: #{@incorrect_guesses.join(', ')}"
    puts "-" * 40
  end

  # ask to savestate,loadstate at start of turn. only show loadstate if loads avaialble
  def run
    while !@lives.zero? && @word_progress.include?("_")
      display
      puts "Enter 's' to save, 'l' to load, or any other key to continue:"
      input = gets.chomp
      save_state if input == "s"
      if input == "l"
        save_state
        load_state
        display
      end

      puts "Enter your guess: "
      letter = gets[0]
      guess letter
    end
    display
    text = @word_progress.include?("_") ? "You lost (╥﹏╥)\nWord was:#{@word}" : "You won ヽ(˃ヮ˂)ノ"
    puts "Game over. #{text}"
  end

  def save_state
    Dir.mkdir("saves") unless Dir.exist?("saves")
    obj = instance_variables.each_with_object({}) do |var, hash|
      hash[var] = instance_variable_get(var)
    end
    @current_save = "save#{incremental_save_number}.yaml" unless File.exist?("saves/#{@current_save}")
    File.write("saves/#{@current_save}", YAML.dump(obj), mode: "w")
  end

  def incremental_save_number
    files = Dir.entries("saves")
    files = files.map do |file|
      file[4..-6].to_i if file.include?("save")
    end
    files = files.compact
    number = 0
    number += 1 while files.include?(number)
    number
  end

  # assuming saves are present
  def self.load_state_menu(obj_file_pair)
    puts "Select a save to load"
    obj_file_pair.each_with_index do |save, index|
      puts "#{index + 1}. #{save[0].instance_variable_get(:@word_progress).join(' ')} |
       #{save[0].instance_variable_get(:@lives)} lives left"
    end
  end

  def load_state
    files = begin
      beginDir.entries("saves")
    rescue StandardError
      []
    end
    obj_file_pair = Hangman.convert_to_saves(files)
    return puts "No saves found" if obj_file_pair.empty?

    Hangman.load_state_menu(obj_file_pair)
    save_number = gets.chomp.to_i - 1
    change_current_state(obj_file_pair[save_number][0])
    @current_save = obj_file_pair[save_number][1]
  end

  def change_current_state(other_object)
    other_object.instance_variables.each do |var|
      value = other_object.instance_variable_get(var)
      instance_variable_set(var, value)
    end
  end

  def self.convert_to_saves(files)
    obj_file_pair = files.map do |file|
      [Hangman.load_file(file), file] if file.include?(".yaml")
    end
    obj_file_pair.compact
  end

  def self.load_file(file)
    pairs = YAML.load_file("saves/#{file}")
    object = Hangman.new
    pairs.each_key do |key|
      object.instance_variable_set(key, pairs[key])
    end
    object
  rescue StandardError => e
    puts "Error loading file: #{e.message}"
    puts e.backtrace.join("\n")
  end
end
