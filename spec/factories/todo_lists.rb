FactoryBot.define do
  factory :todo_list do
    name { Faker::Appliance.equipment + " List" }
  end
end
