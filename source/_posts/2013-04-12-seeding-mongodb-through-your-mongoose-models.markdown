---
layout: post
title: Seeding mongodb through your mongoose models
tags:
- Development
- MongoDB
- Mongoose
- Node.js
status: publish
type: post
published: true
meta:
  _edit_last: '1'
  _syntaxhighlighter_encoded: '1'
---
<strong>23/4/2013 Update:</strong>
<em>A change implementing promise support for the </em><code>create</code><em> function <a href="https://github.com/LearnBoost/mongoose/commit/2ef5f237e054fc4846143530410e353ef7a7456e">was just committed to GitHub</a>, and should be available in the 3.7 release of Mongoose. Sweet!</em>

Just wanted to share a nice little technique I discovered when working on a project using the wonderful <a href="http://mongoosejs.com/">Mongoose</a> library to interact with a MongoDB database in Node.js. I was writing some integration tests, and needed to reset and seed the database from a set of JSON files before running each test. I really wanted to do this through my existing Mongoose models, so that I could get all the seed data validated before running my tests. Since there also are relations between my different collections I needed to insert the collections in a certain order, so my first attempt quickly devolved into a textbook example of the good ol' pyramid of doom:

<pre>
[javascript]
User.remove({}, function(err) {
    if(err) { return done(err); }

    Exercise.remove({}, function(err) {
        if(err) { return done(err); }

        WorkoutTemplate.remove({}, function(err) {
            if(err) { return done(err); }

            User.create(require('../../data/users.json'), function(err) {
                if(err) { return done(err); }

                Exercise.create(require('../../data/exercises.json'), function(err) {
                    if(err) { return done(err); }

                    WorkoutTemplate.create(require('../../data/workoutTemplates.json'), function(err) {
                        if(err) { return done(err); }
                        else    { return done(); }
                    });
                });
            });
        });
    });
});
[/javascript]
</pre>

In the above code snippet <strong>User</strong>, <strong>Exercise</strong>, and <strong>WorkoutTemplate </strong>are my mongoose models, and since my <strong>WorkoutTemplate </strong>schema references my <strong>Exercise </strong>schema I need to insert data in that specific order. Using Mongoose's <code>remove</code> function with an empty object as the first argument will clear everything from the related collection. Furthermore, the <code>create</code> function will attempt to do a batch insert of the array you hand it. However, as you can see this quickly devolved into callback hell, and that was with just three different collections! Fortunately, I discovered that the <code>exec</code> function, which you can call on query objects, returns a promise object. This means I can just make a pretty, little promise chain instead of using callbacks.

There is just one obstacle to this... The <code>create</code> function does not return a query object, meaning we can't call <code>exec</code> on it to return a promise... I decided to rectify this by attaching a new function on the base mongoose Model which basically just wraps the <code>create</code> function, but actually returns a promise object.

<pre>
[javascript]
var mongoose = require('mongoose');
mongoose.Model.seed = function(entities) {
	var promise = new mongoose.Promise;
	this.create(entities, function(err) {
		if(err) { promise.reject(err); }
		else    { promise.resolve(); }
	});
	return promise;
};
[/javascript]
</pre>

So, finally I am able to create a nice and neat promise chain in the <code>beforeEach</code> function of my test suite. Voil  !

<pre>
[javascript]
beforeEach(function(done) {
	
	...

	// Reset collections
	User.remove().exec()
		.then(function() { Exercise.remove().exec() })
		.then(function() { WorkoutTemplate.remove().exec() })

		// Seed
		.then(function() { User.seed(require('../scaffolds/users.json')) })
		.then(function() { Exercise.seed(require('../scaffolds/exercises.json')); })
		.then(function() { WorkoutTemplate.seed(require('../scaffolds/workoutTemplates.json')); })
                
		// Finito!
		.then(function() { done(); }, function(err) { return done(err); });

	...
	
});
[/javascript]
</pre>
