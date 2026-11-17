# API integration (not implemented)

Source of truth for endpoint paths and request/response contracts is the
current `Andril-Backend/contracts/openapi/andril-api.v1.yaml`, checked
against the latest branch before writing a Flutter client.

The M5 audit (16 Nov 2026) reported account/onboarding routes present,
but private module-profile identity, Social questionnaire answer services,
Social matching, Groups, and contextual recommendations unavailable.
Do not add guessed endpoints or use mock JSON as an authoritative contract.
