#import "../../../../Pods/tuneup_js/tuneup.js"

test("expectFirstIntroScreenShowsLoginButton", function (target, app) {
    assertWindow({
        buttons:[
            { name:"continueButton" },
            { name:"loginNowButton", isVisible:true }
        ],
        onPass:function (window) {
            window.buttons()["continueButton"].tap();
        }
    });
});


test("expectSecondIntroScreenDoesNotShowLoginButton", function (target, app) {
    target.delay(1); // Wait for animation to make disappear.
    assertWindow({
        buttons:[
            { name:"continueButton", label:"Continue"},
            { name:"loginNowButton", isVisible:false }
        ],
        onPass:function (window) {
            window.buttons()["continueButton"].tap();
        }
    });
});

test("expectThirdIntroScreenDoesNotShowLoginButton", function (target, app) {
    assertWindow({
        buttons:[
            { name:"continueButton", label:"Continue"},
            { name:"loginNowButton", isVisible:false }
        ],
        onPass:function (window) {
            window.buttons()["continueButton"].tap();
        }
    });
});

test("expectFourthIntroScreenDoesNotShowLoginButton", function (target, app) {
    assertWindow({
        buttons:[
            { name:"continueButton", label:"Continue"},
            { name:"loginNowButton", isVisible:false }
        ],
        onPass:function (window) {
            window.buttons()["continueButton"].tap();
        }
    });
});

test("expectFifthIntroScreenDoesNotShowLoginButtonAndShowsGetStarted", function (target, app) {
    target.delay(1); // Wait for animation.
    assertWindow({
        buttons:[
            { name:"continueButton", label:"Get Started" },
            { name:"loginNowButton", isVisible:false }
        ],
        onPass:function (window) {
            window.buttons()["continueButton"].tap();
        }
    });
});


test("expectEnterBabyInfoScreenIsShown", function (target, app) {
    target.delay(1); // Wait for animation.
    assertWindow({
        navigationBar:{ name:"About Baby" }
    });
});

