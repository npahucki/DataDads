Feature: As a user of DataParenting, I want to be able to enter my baby's information so I can start using the App

  Scenario: Going through the initial setup process
    Given I launch the app
    Then I should be on the "Intro" screen

    When I tap the button "GET STARTED"
    Then I should be on the "About Your Baby" screen

    When I tap the text field "Baby name" and type "Mateo"
    Then I tap the button "Girl"
    Then I tap the navigation button "Next"

    Then I should be on the "Baby photo" screen

    When I tap the button "Add picture"
    Then I should see an action sheet choice "Choose from library"
  # TODO: When run on phone, take a picture!
    Then I tap the button "Cancel"
    Then I tap the navigation button "Next"

    Then I should be on the "About you" screen



