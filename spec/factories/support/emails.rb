FactoryBot.define do
  factory :support_email, class: "Support::Email" do
    subject { "MyString" }
    body { "MyText" }
    sender { "" }
    recipients { "" }
    conversation_id { "MyString" }
    case_id { "" }
    sent_at { "2021-12-15 11:51:12" }
    received_at { "2021-12-15 11:51:12" }
    read_at { "2021-12-15 11:51:12" }
    association :case, factory: :support_case
  end
end
