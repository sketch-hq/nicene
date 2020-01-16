%{
  configs: [
    %{
      name: "default",
      checks: [
        {Nicene.FileAndModuleName, []},
        {Nicene.UnnecessaryPatternMatching, []},
        {Nicene.FileTopToBottom, []},
        {Nicene.PublicFunctionsFirst, []},
        {Nicene.ConsistentFunctionDefinitions, []},
        {Nicene.TrueFalseCaseStatements, []},
        {Nicene.TestsInTestFolder, []},
        {Nicene.NoSpecsPrivateFunctions, []}
      ]
    }
  ]
}
