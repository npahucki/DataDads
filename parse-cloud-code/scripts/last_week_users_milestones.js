/*
This script will retrieve a list of the new users from last week and count their milestones
 */

var Parse = require('./init_parse').createParse();

var _ = require('underscore');
var date = require ('datejs');

var lastWeekUsersQuery = new Parse.Query('User');
lastWeek = (7).days().ago();
lastWeekUsersQuery.greaterThan('createdAt', lastWeek);


lastWeekUsersQuery.each(function(user){
  var userBabiesQuery = new Parse.Query('Babies');
  userBabiesQuery.equalTo('parentUser', user); // NOTE: You can use the the User object directly here, you do not need to create your own JSON object and populate it with the id. 
  return userBabiesQuery.find()
  .then(function(babies) {
        // Look up achievements for babies
        var achievementQuery = new Parse.Query("MilestoneAchievements");
        achievementQuery.containedIn("baby", babies);
        return achievementQuery.count();
    }).then(function(countOfAchievements) {
          console.log("User " + user.id + " has " + countOfAchievements + " achievements");
    });
}).then(function(){
  console.log('done with users');
}, function(error){
  console.log("error: " + error);
});

// Parse.Promise.when( lastWeekUsersQuery.find() ).
//   then( function(results){
//     _.each(results, function(user){
//       console.log('got user: ' + user.id);
      
//     });
//   }, function(error){
//     console.log(error);
// });


// function getUserBabies(userId){
//   userBabiesQuery = new Parse.Query('Babies');
//   userBabiesQuery.equalTo('parentUser', {__type:"Pointer", className: 'User', objectId: userId});
//   userBabiesQuery.find();


// }


// lastWeekUsersQuery.each(function(user){
  
//   console.log("Babies for user id: " + user.id);
  
//   userBabiesQuery = new Parse.Query('Babies');
//   userBabiesQuery.equalTo('parentUser', {__type:"Pointer", className: 'User', objectId: user.id});  
//   userBabiesQuery.each(function(baby){
//     console.log('on each baby ' + baby);
//     console.log(baby);
//   }).then(function(baby){
//     console.log('done with babies for ' + user.id);
//   }, function(error){
//     console.log('error on babies:' + error);
//   });
// }).then(function(){
//   console.log('done with users');
// }, function(error){
//   console.log("error: " + error);
// });
