# jspreprocess-brunch
Adds C-style preprocessor directive support to JS [brunch](http://brunch.io) compilations. This allows you to have the same source files, but multiple config.coffee files to compile for different environments.

## Setup
Add `"jspreprocess-brunch": "x.y.z"` to `package.json` of your brunch app.

In each `config.coffee` file of your brunch app, add a line to specify your `buildTarget`.

It can also be helpful to have different public paths for each config. That way different configurations with different buildTarget's will compile their output to different folders.

ex: `config_prod.coffee`
```coffeescript
exports.config =
  buildTarget: 'PRODUCTION'
  paths:
    public: 'prod'
  ...
```

ex: `config_debug.coffee`
```coffeescript
exports.config =
  buildTarget: 'DEBUG'
  paths:
    public: 'debug'
  ...
```

## Add Directives to Code
Directives for if, else, elif, and endif are available to control what javascript gets compiled. Each must be on its own line and prepended by the double slash comment op. 

```javascript
// #BRUNCH_IF (PRODUCTION)
...

// #BRUNCH_ELIF (DEBUG)
...

// #BRUNCH_ELSE
...

// #BRUNCH_ENDIF
```

Note the use of parentheses. Unlike C preprocessor directives, those parentheses are required for `#BRUNCH_IF` and `#BRUNCH_ELIF` statements.

The `#BRUNCH_IF` and `#BRUNCH_ELIF` directives also support the OR (||) operator.
ex: `// #BRUNCH_IF (PRODUCTION || iOS)`

* Nested `#BRUNCH_IF` statements are not yet supported.

## Compile Your Brunch App
Using the config_prod.coffee and config_debug.coffee examples from before, you can compile each config like so:

* `brunch build -c config_prod`
* `brunch build -c config_debug`
