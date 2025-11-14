# Foundation Tools for Swift

KISS


## Project Layout

```mermaid
flowchart TD
    FoundationCommon
    FoundationCommonTests{{FoundationCommonTests}}-->FoundationCommon
    FoundationTools-->FoundationCommon
    FoundationTools-->FoundationTypes
    FoundationTools-->Logging[[Logging]]
    FoundationTools-->OpenCombine[[OpenCombine]]
    FoundationToolsTests{{FoundationToolsTests}}-->FoundationTools
    FoundationTypes-->kvSIMD[[kvSIMD]]
    FoundationTypesTests{{FoundationTypesTests}}-->FoundationTypes
```