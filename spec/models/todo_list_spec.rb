require 'rails_helper'

describe TodoList do
  describe "validations" do
    context 'when list has no name' do
      let(:list) { build(:todo_list, name: nil) }

      it 'is invalid' do
        expect(list.valid?).to be_falsey
      end
    end
  end

  context 'when creating a new todo list' do
    let(:list) { FactoryBot.create(:todo_list) }

    before do
      list
    end

    it 'creates list' do
      expect(list.id).to be_present
    end
  end
end
