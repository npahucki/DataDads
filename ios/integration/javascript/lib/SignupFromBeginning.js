#import "../../../../Pods/tuneup_js/tuneup.js"

var userName = Math.random().toString(36) + "@blah.com";
var password = "blah";

test("expectCanSignupWithNewAccount", function (target, app) {
    target.frontMostApp().mainWindow().buttons()["loginNowButton"].tap();
    target.frontMostApp().mainWindow().buttons()["No account yet? Sign Up!"].tap();
    target.frontMostApp().mainWindow().scrollViews()[0].textFields()[0].textFields()[0].tap();
    target.frontMostApp().keyboard().typeString(userName);
    target.frontMostApp().mainWindow().scrollViews()[0].secureTextFields()[0].secureTextFields()[0].tap();
    target.frontMostApp().keyboard().typeString(password);
    target.frontMostApp().mainWindow().scrollViews()[0].buttons()["Sign Up"].tap();


    // Make sure Baby Info Page is Shown
    retry(function () {
        assertWindow({
            navigationBar:{ name:"About Baby" }
        });
    }, 5);
});


