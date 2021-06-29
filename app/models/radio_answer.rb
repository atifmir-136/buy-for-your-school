class RadioAnswer < ApplicationRecord
  include TaskCounters

  belongs_to :step

  validates :response, presence: true
end
