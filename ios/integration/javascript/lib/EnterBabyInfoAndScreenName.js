#import "../../../../Pods/tuneup_js/tuneup.js"


// Baby Info Screen
test("expectEnteringBabyInfoEnablesNextStep", function (target, app) {

    // Make sure Baby Info Page is Shown
    retry(function () {
        assertWindow({
            navigationBar:{ name:"About Baby" }
        });
    }, 5);

    assertWindow({
        navigationBar:{ rightButton:{ isEnabled:false}, leftButton:{isEnabled:true}}
    });

    target.frontMostApp().mainWindow().textFields()[0].textFields()[0].tap();
    target.frontMostApp().keyboard().typeString("My Test Baby");
    target.frontMostApp().mainWindow().textFields()[1].textFields()[0].tap();
    target.frontMostApp().windows()[1].pickers()[0].wheels()[0].tapWithOptions({tapOffset:{x:0.25, y:0.44}});
    target.frontMostApp().windows()[1].pickers()[0].wheels()[1].tapWithOptions({tapOffset:{x:0.52, y:0.44}});
    target.frontMostApp().mainWindow().textFields()[2].textFields()[0].tap();
    target.frontMostApp().windows()[1].pickers()[0].wheels()[1].dragInsideWithOptions({startOffset:{x:0.28, y:0.41}, endOffset:{x:0.28, y:0.63}});
    target.tap({x:266.00, y:290.50});
    target.frontMostApp().mainWindow().buttons()[0].tap(); // Male Button

    assertWindow({
        navigationBar:{ rightButton:{ isEnabled:true}},
        onPass:function (window) {
            window.navigationBar().rightButton().tap(); // Next Button
        }
    });
});

// Baby Photo (skipped) - Can't get files onto simulator (Maybe in script?)
test("expectPhotoCanBeSkipped", function (target, app) {
    assertWindow({
        navigationBar:{ name:"Baby's Mug Shot" }
    });
    target.frontMostApp().mainWindow().buttons()["cameraButton"].tap();
    target.frontMostApp().actionSheet().cancelButton().tap();
    assertWindow({
        navigationBar:{ rightButton:{ isEnabled:true}},
        onPass:function (window) {
            target.frontMostApp().navigationBar().rightButton().tap();
        }
    });
});

test("expectCanCheckExistingTag", function (target, app) {
    assertWindow({
        navigationBar:{ name:"Baby's Tags" }
    });

    var tagTable = target.frontMostApp().mainWindow().tableViews()["tagTable"];
    assertEquals(tagTable.cells()[1].value(), "unchecked");
    tagTable.cells()[1].tap();
    assertEquals(tagTable.cells()[1].value(), "checked");
});

test("expectCantAddBlankTag", function (target, app) {
    assertWindow({
        navigationBar:{ name:"Baby's Tags" }
    });

    var tagTable = target.frontMostApp().mainWindow().tableViews()["tagTable"];
    target.frontMostApp().mainWindow().textFields()["enterNewTagTextField"].tap();
    assertFalse(target.frontMostApp().mainWindow().buttons()["addNewTagButton"].isEnabled());

    target.frontMostApp().mainWindow().textFields()["enterNewTagTextField"].tap();
    target.frontMostApp().keyboard().typeString("New Test Tag");
    target.frontMostApp().mainWindow().buttons()["addNewTagButton"].tap();
    // Should be automatically selected and added as first tag
    assertEquals(tagTable.cells()[0].label(), "New Test Tag");
    assertEquals(tagTable.cells()[0].value(), "checked");

    assertWindow({
        navigationBar:{ rightButton:{ isEnabled:true}},
        onPass:function (window) {
            target.frontMostApp().navigationBar().rightButton().tap();
        }
    });
});

test("expectEnteringScreenNameEnablesNextStepAndProfileIsSaved", function (target, app) {

    // Make sure Baby Info Page is Shown
    retry(function () {
        assertWindow({
            navigationBar:{ name:"About You" }
        });
    }, 5);

    assertWindow({
        navigationBar:{ rightButton:{ isEnabled:false}, leftButton:{isEnabled:true}}
    });
    target.frontMostApp().mainWindow().textFields()["screenNameTextField"].tap();
    target.frontMostApp().keyboard().typeString("Test Screen Name");
    target.frontMostApp().mainWindow().buttons()[0].tap(); // Male button tap
    assertWindow({ navigationBar:{ rightButton:{ isEnabled:true}} });

//    Terms and Conditions Dialog - TODO: Assert web view loads T & C
    target.frontMostApp().mainWindow().buttons()["(read them now, we dare you)"].tap();
    target.frontMostApp().mainWindow().buttons()["modalBoxClose"].tap();
    // Uncheck agree
    target.frontMostApp().mainWindow().buttons()["I accept the terms and conditions"].tap();
    assertWindow({ navigationBar:{ rightButton:{ isEnabled:false}} });

    target.frontMostApp().mainWindow().buttons()["I accept the terms and conditions"].tap();
    assertWindow({ navigationBar:{ rightButton:{ isEnabled:true}},
        onPass:function (window) {
            target.frontMostApp().navigationBar().rightButton().tap(); // Done Button.
        }
    });

    retry(function () {
        assertWindow({
            navigationBar:{ name:"My Test Baby" }
        });
    }, 5, 2);
});



// Screen Name





