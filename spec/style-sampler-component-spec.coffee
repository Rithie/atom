StyleSamplerComponent = require '../src/style-sampler-component'

fdescribe "StyleSamplerComponent", ->
  [editor, styleSamplerComponent, stylesContainerNode, functionsFonts, parametersFonts, defaultFonts] = []

  beforeEach ->
    waitsForPromise ->
      atom.packages.activatePackage('language-javascript')

    waitsForPromise ->
      atom.project.open('sample.js').then (o) -> editor = o

    runs ->
      styleSamplerComponent = new StyleSamplerComponent(editor)
      stylesContainerNode = document.createElement("div")

      document.body.appendChild(styleSamplerComponent.getDomNode())
      document.body.appendChild(stylesContainerNode)

    waitsFor "iframe initialization", ->
      styleSamplerComponent.canMeasure()

    runs ->
      functionsFonts = []
      parametersFonts = []
      defaultFonts = []

      styleSamplerComponent.onDidInvalidateStyles ->
        functionsFonts.length = 0
        parametersFonts.length = 0
        defaultFonts.length = 0

      styleSamplerComponent.onDidSampleScopesStyle ({scopes, font}) ->
        scopeIdentifier = scopes.join()

        if scopeIdentifier.indexOf("entity.name.function") isnt -1
          functionsFonts.push(font)
        else if scopeIdentifier.indexOf("parameters") isnt -1
          parametersFonts.push(font)
        else
          defaultFonts.push(font)

      styleSamplerComponent.setDefaultFont("Times", "12px")
      styleSamplerComponent.addStyleElements([
        styleElementWithSelectorAndFont(".entity.name.function", "Arial", "20px")
        styleElementWithSelectorAndFont(".parameters", "Helvetica", "32px")
      ])

  afterEach ->
    styleSamplerComponent.getDomNode().remove()
    stylesContainerNode.remove()

  it "samples font styles for the desired screen rows", ->
    styleSamplerComponent.sampleScreenRows([0])

    expect(functionsFonts.length).toBeGreaterThan(0)
    expect(parametersFonts.length).toBeGreaterThan(0)
    expect(defaultFonts.length).toBeGreaterThan(0)

    for functionFont in functionsFonts
      expect(functionFont).toEqual("normal normal normal normal 20px/normal Arial")

    for parameterFont in parametersFonts
      expect(parameterFont).toEqual("normal normal normal normal 32px/normal Helvetica")

    for defaultFont in defaultFonts
      expect(defaultFont).toEqual("normal normal normal normal 12px/normal Times")

  it "invalidates samplings when the default font changes", ->
    styleSamplerComponent.sampleScreenRows([0])

    expect(functionsFonts.length).toBeGreaterThan(0)
    expect(parametersFonts.length).toBeGreaterThan(0)
    expect(defaultFonts.length).toBeGreaterThan(0)

    oldFunctionFonts = functionsFonts.slice()
    oldParametersFonts = parametersFonts.slice()

    styleSamplerComponent.setDefaultFont("Arial", "12px")

    expect(functionsFonts.length).toBe(0)
    expect(parametersFonts.length).toBe(0)
    expect(defaultFonts.length).toBe(0)

    styleSamplerComponent.sampleScreenRows([0])

    expect(functionsFonts).toEqual(oldFunctionFonts)
    expect(parametersFonts).toEqual(oldParametersFonts)
    expect(defaultFonts.length).toBeGreaterThan(0)

    for defaultFont in defaultFonts
      expect(defaultFont).toEqual("normal normal normal normal 12px/normal Arial")

  # it "samples a screen row twice only if the row has changed", ->
  # it "does not sample the same scopes twice", ->
  # it "invalidates samples when styles change", ->

  styleElementWithSelectorAndFont = (selector, fontFamily, fontSize) ->
    style = document.createElement("style")
    style.innerHTML = """
    #{selector} {
      font-family: #{fontFamily};
      font-size: #{fontSize};
    }
    """
    stylesContainerNode.appendChild(style)
    style
