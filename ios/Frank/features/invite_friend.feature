Feature: Baby Monitor
  Monitoring a baby means getting emails every time the baby logs an achievement.
  In the case where both inviter and invitee are already users, the relationship is mutual - they each get
  emails about the the others' babies' achievements.
  The invited person may already be a DataParenting user, or may not be and
    a) may never install the App (e.g. grandma).
      i) the person receiving the email may stop the emails by clicking an unsubscribe link.
    b) may later install the App.
      i) once the user has installed the app and signed up, he should immediately be able to see in the
  Monitors tab a relationship to the person(s) for whom he was already receiving emails.
      ii) he may delete the relationship by using the Monitors section of the App
      iii) he may delete the relationship by clicking the unsubscribe link in the emails he gets, before or after installing the App

  Scenario: Send an invitation / add monitor for your baby
    Given I have already signed in
    Then I go to the "Monitors" Tab
    And I tap the navigation button "+"
    And I allow access to the address book if I am prompted
    Then I type in the name of a contact to whom I want to monitor my baby.
    And I tap the navigation button "Done"
    Then I see a an new item in the "Monitors" Tab table.

  Scenario: Receive a Monitor invitation (already a user)
    Given I have already signed in
    Then I should recieve a push notification indicating that someone is Monitoring my baby.
    And I should receive an email with the last achievement with a picture (or one without if none with picture found).
    When I go to the "Monitors" Tab
    Then I see a an new item in the "Monitors" Tab table.




  Scenario: Ignore an upcoming milestone
  TODO!


  Scenario: Postpone an upcoming milestone
  TODO!
