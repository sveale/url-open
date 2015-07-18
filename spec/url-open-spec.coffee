cp = require 'copy-paste'

describe "copy-paste", ->
  describe "when something is copied", ->
    it "is pasted", ->
      testString = "askfh42t290sgkj"
      cp.copy(testString, ->
        cp.paste((result) ->
          expect(result).toEqual testString
        )
      )
