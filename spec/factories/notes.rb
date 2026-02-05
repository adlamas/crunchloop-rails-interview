FactoryBot.define do
  factory :note do
    content { Faker::Lorem.paragraph(sentence_count: 2) }

    # This tells FactoryBot to look for a :todo_list factory
    # and create one automatically if you don't provide it.
    association :todo_list
  end
end
