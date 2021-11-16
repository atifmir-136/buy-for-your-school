describe "Support agent sends a templated email" do
  include_context "with an agent"
  include_context "with notify email templates"

  let(:support_case) { create(:support_case, :open) }

  before do
    click_button "Agent Login"
    visit support_case_path(support_case)
    click_link "Send email"
    choose "Template"
    click_button "Save"
  end

  describe "list of templates" do
    it "displays all available email templates to choose from" do
      # support.case_email_templates.index.what_is_a_framework.link_text
      expect(page).to have_link "What is a framework?",
                                href: "/support/cases/#{support_case.id}/email/content/f4696e59-8d89-4ac5-84ca-17293b79c337"

      # support.case_email_templates.index.how_to_approach_suppliers.link_text
      expect(page).to have_link "How to approach suppliers",
                                href: "/support/cases/#{support_case.id}/email/content/6c76ed8c-030e-4c69-8f25-ea0c66091bc5"

      # support.case_email_templates.index.catering_frameworks.link_text
      expect(page).to have_link "Catering frameworks",
                                href: "/support/cases/#{support_case.id}/email/content/12430165-4ae7-47aa-baa3-d0b3c5440a9b"

      # support.case_email_templates.index.social_value.link_text
      expect(page).to have_link "Social value",
                                href: "/support/cases/#{support_case.id}/email/content/bb4e6925-3491-44b8-8747-bdbb31257403"
    end
  end

  describe "selecting a template" do
    before do
      click_link "What is a framework?"
    end

    it "previews the email with variables substituted" do
      within ".email-preview" do
        expect(page).to have_content "Hi School Contact, here is information regarding frameworks"
      end
    end
  end

  describe "sending the email" do
    let(:email) do
      {
        email_address: "school@email.co.uk",
        template_id: "ac679471-8bb9-4364-a534-e87f585c46f3",
        reference: "000001",
        personalisation: {
          reference: "000001",
          first_name: "School",
          last_name: "Contact",
          email: "school@email.co.uk",
          text: "Hi School Contact, here is information regarding frameworks",
          from_name: "Procurement Specialist",
        },
      }
    end

    before do
      stub_request(:post, "https://api.notifications.service.gov.uk/v2/notifications/email")
      .with(body: email.to_json)
      .to_return(body: {}.to_json, status: 200, headers: {})

      click_link "What is a framework?"
    end

    it "saves the email as a case interaction" do
      expect(Rollbar).to receive(:info).with("Sending email to school")

      click_button "Confirm and send email"

      interacton = support_case.reload.interactions.last

      expect(interacton.event_type).to eq "email_to_school"
      expect(interacton.body).to eq "Hi School Contact, here is information regarding frameworks"
      expect(interacton.agent).to eq agent
    end
  end
end
