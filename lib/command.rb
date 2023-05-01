
module Command
  @commands = {}

  def self.register action
    @commands[action.command] = action
  end

  def self.launch!
    command = ARGV.shift
    is_executed = false
    @commands.each do |k, action|
      if k == command
          is_executed = true
          action.apply(ARGV)
      end
    end

    unless is_executed
      display_help
    end
  end

  def self.display_help
    puts "taskman [commande] [contenu|id] [ options...]"
    puts "............................................."
    @commands.each do |k, action|
      puts action.to_s
    end
  end

  class Action
    attr_accessor :command, :arguments, :description, :block

    def initialize command, arguments, description, &block
      @command = command
      @arguments = arguments
      @description = description
      @block = block
    end

    def apply arguments
      begin
        block.call(arguments)

      rescue TaskmanError => exception
        puts "ERROR: #{exception.message}".light_red.bold
      end
    end

    def register!
      Command.register(self)
    end

    def to_s
      puts "#{@command} #{@arguments}\t *#{@description}"
    end
  end


  class TaskAction < Action
    def initialize command, arguments, description, &block
      super command, arguments, description, &block
    end

    def apply arguments
      id = arguments.shift.to_i
      task = Task.get_task(id )

      if task.nil?

        puts "la tache #{id} n'existe pas!"
        exit
      end

      begin
        block.call(arguments)

      rescue TaskmanError => exception
        puts "ERROR: #{exception.message}".light_red.bold
      # rescue => exception
      #   puts "ERROR: une erreur ruby!".light_red.bold
      end
      # block.call(task, arguments)
    end

    def to_s
      puts "#{@command} :id #{@arguments}\t *#{@description}"
    end
  end


  def self.define &block
    CommandDSL.new(&block)
  end

  class CommandDSL

    def initialize &block
      instance_eval(&block)
    end

    def args str
      @args = str
    end

    def desc str
      @desc = str
    end

    def action name, &block
      Command::Action.new(name.to_s, @args, @desc, &block).register!
      @args = ""
      @desc = ""
    end

    def task_action name, &block
      Command::TaskAction.new(name.to_s, @args, @desc, &block ).register!
      @args = ""
      @desc = ""
    end
  end
end


# un DSL
Command.define do
  args ":contenu (options...)"
  desc "cree une nouvelle tache."
  action :add do |arguments|
    Task.add(arguments)
  end

  args ""
  desc "Supprimer une tache"
  task_action :del do |arguments|
    Task.delete task.id
  end

  args ":filtres"
  desc "Liste des taches"
  action :list do |arguments|
    filters = arguments.inject({}) do |h, x|
      k, v = x.split(":")

      if v.nil?
        h[:content] = k
      else
        h[k.to_sym] = v
      end
      h
    end
    Task.display filters
  end

  args ""
  desc "Supprime ttes les taches"
  action :clear do |arguments|
    Task.clear
  end

end

def on_command action
  $command ||= ARGV.shift

  if action == $command
    yield (ARGV)
    $command_faite = true
  end

end
