var express = require('express');
var moment = require('moment');
var _ = require('underscore');

// Required for initializing Express app in Cloud Code.
var app = express();

// Global app configuration section
app.set('views', 'cloud/views');
app.set('view engine', 'ejs');
app.use(express.bodyParser());
//app.use(express.methodOverride());


// You can use app.locals to store helper methods so that they are accessible
// from templates.
app.locals._ = _;
app.locals.formatTime = function(time) {
  return moment(time).format('MMMM Do YYYY, h:mm a');
};

app.get('/achievements/:id', require('cloud/controllers/achievements.js').show);
app.get('/unsubscribe',  require('cloud/controllers/unsubscribe.js').show);

app.listen();