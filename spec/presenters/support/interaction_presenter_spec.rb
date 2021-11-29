RSpec.describe Support::InteractionPresenter do
  subject(:presenter) { described_class.new(interaction) }

  let(:interaction) { OpenStruct.new(note: "\n foo \n") }
  let(:event_types) do
    {
      note: 0,
      phone_call: 1,
      email_from_school: 2,
      email_to_school: 3,
      support_request: 4,
      hub_notes: 5,
      progress_notes: 6,
    }
  end

  describe "#note" do
    it "strips new lines" do
      expect(presenter.note).to eq("foo")
    end
  end

  describe "#contact_options" do
    it "returns a formatted hash for the log contact form" do
      expect(presenter.contact_options).to match_array([
        have_attributes(id: "phone_call", label: "Phone call"),
        have_attributes(id: "email_from_school", label: "Email from school"),
        have_attributes(id: "email_to_school", label: "Email to school"),
      ])
    end
  end

  describe "#show_body" do
    context "with an interaction via email" do
      let(:interaction) { create(:support_interaction, :email_to_school) }

      it "provides a link to a preview of the email" do
        expect(presenter.show_body).to eq("<a href=\"/support/cases/#{interaction.case_id}/interactions/#{interaction.id}\" target=\"_blank\">Open email preview in new tab</a>")
      end
    end

    context "with a non-email interaction" do
      let(:interaction) { create(:support_interaction, :phone_call) }

      it "returns the body of the interaction" do
        expect(presenter.show_body).to eq(interaction.body)
      end
    end
  end
end
