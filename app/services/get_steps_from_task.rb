class GetStepsFromTask
  class RepeatEntryDetected < StandardError; end

  attr_accessor :task

  def initialize(task:)
    self.task = task
  end

  def call
    return [] unless task.respond_to?(:steps)
    step_ids = []
    task.steps.each do |step|
      if step_ids.include?(step.id)
        send_rollbar_error(message: "A repeated Contentful entry was found in the same task", entry_id: step.id)
        raise RepeatEntryDetected.new(step.id)
      else
        step_ids << step.id
      end
    end

    step_ids.map { |entry_id|
      GetEntry.new(entry_id: entry_id).call
    }
  end

  private

  def send_rollbar_error(message:, entry_id:)
    Rollbar.error(
      message,
      contentful_url: ENV["CONTENTFUL_URL"],
      contentful_space_id: ENV["CONTENTFUL_SPACE"],
      contentful_environment: ENV["CONTENTFUL_ENVIRONMENT"],
      contentful_entry_id: entry_id
    )
  end
end
