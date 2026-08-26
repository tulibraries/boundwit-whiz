# Boundwit Whiz

Boundwit Whiz is a Rails application for creating and maintaining bound-with relationships in Alma.

The application accepts a list of Alma MMS IDs, treats the first bibliographic record as the parent, and updates the related MARC bibliographic and holding records so the titles are represented as a bound-with set.

## What it does

Given a list of MMS IDs, Boundwit Whiz:

- Treats the first bib as the parent record.
- Adds `774` fields to the parent for each child bib.
- Adds a `773` field to each child pointing back to the parent.
- Adds a `501` "Bound with:" note to each bib describing the other titles in the set.
- Adds `014` fields to the selected holding record for the related MMS IDs.
- Updates the records in Alma.
- Caches the updated MARC records locally so they can be displayed without making another Alma API request.

Alma remains the source of truth. Cached MARC records can be refreshed from Alma.

## Requirements

- Ruby
- Rails
- SQLite for local development
- Access to the Alma API
- Temple SSO configuration when authentication is enabled

Install dependencies:

```bash
bundle install
````

Prepare the database:

```bash
bin/rails db:prepare
```

## Configuration

### Alma

The application uses the `alma` Ruby gem to communicate with Alma.

Set an Alma API key:

```bash
export ALMA_API_KEY=...
```

The API key must have permission to read and update the bibliographic, holding, and user records required by the application.

### Authentication

Production access is restricted to users who:

1. Authenticate through Temple SSO.
2. Have the `Cataloger` role in Alma.

The application checks the Alma user associated with the SSO identity before granting access.

Development and test environments can disable this access requirement.

For example:

```ruby
# config/environments/development.rb

config.x.require_cataloger_access =
  ENV.fetch("REQUIRE_CATALOGER_ACCESS", "false") == "true"
```

Normal local development:

```bash
bin/dev
```

To exercise the real SSO and Alma authorization flow locally:

```bash
REQUIRE_CATALOGER_ACCESS=true bin/dev
```

Production should always have cataloger access enforcement enabled.

## Development

Start the development environment with:

```bash
bin/dev
```

`bin/dev` runs Rails as well as the Dart Sass watcher used to compile the application's Bootstrap styles.

The application uses:

* Rails 8
* RSpec
* Bootstrap
* Dart Sass
* Propshaft
* Importmaps
* Stimulus
* OmniAuth SAML
* ruby-marc

## Testing

Run the complete test suite:

```bash
bundle exec rspec
```

Or run an individual spec:

```bash
bundle exec rspec spec/models/marc_record_spec.rb
```

The test suite should not communicate with Temple SSO or Alma directly. External behavior should be mocked at those boundaries.

OmniAuth test mode is used for SAML request specs.

## Application structure

### BoundWith::Updater

`BoundWith::Updater` coordinates a bound-with operation.

It is responsible for:

1. Retrieving bib records from Alma.
2. Determining which holding on the parent bib should be updated.
3. Retrieving the selected parent holding.
4. Applying MARC changes.
5. Saving the changed records back to Alma.
6. Updating the local MARC cache.

MARC-specific manipulation belongs in `BoundWith::MarcEditor` rather than in the controller or updater.

### BoundWith::MarcEditor

`BoundWith::MarcEditor` contains the MARC manipulation logic, including creation and removal of:

* `014`
* `501`
* `773`
* `774`

Keeping this logic separate makes it possible to test MARC transformations without making Alma API requests.

### Alma overrides

The application extends several classes from the `alma` gem under:

```text
app/lib/alma/
```

These overrides provide application-specific behavior such as:

* Converting Alma MARCXML into `MARC::Record` instances.
* Updating bib and holding records.
* Retrieving holdings.
* Checking whether an Alma user is a cataloger.
* Adapting `Alma::ResultSet` to behave correctly with Ruby's `Enumerable` methods.

Overrides are prepended to the appropriate Alma classes from the Alma initializer.

When modifying these overrides, add regression coverage for the actual Alma class as well as the added behavior.

In particular, changes to `Alma::ResultSet#each` should verify that every record is yielded exactly once. Duplicate iteration can result in duplicate MARC fields being written to Alma.

### MarcRecord

`MarcRecord` stores the application's local cached copy of an Alma MARC record.

A record contains:

```text
record_id
record_type
mms_id
title
marc_xml
```

`record_type` is currently either:

```text
bib
holding
```

For a bib:

```text
record_id = MMS ID
mms_id    = MMS ID
```

For a holding:

```text
record_id = holding ID
mms_id    = parent bib MMS ID
```

Only one cached copy of a given Alma record is retained. Alma is authoritative.

A cached record can be refreshed using:

```ruby
marc_record.refresh_from_alma!
```

## Bound-with workflow

The order of the supplied MMS IDs is significant.

For:

```text
991000000000000001
991000000000000002
991000000000000003
```

the first record is the parent:

```text
991000000000000001
```

and the remaining records are children.

The parent must already have the holding/item record that represents the physical bound volume.

Child bibs do not need their own inventory.

### Holding selection

When MMS IDs are entered, the application can retrieve the holdings associated with the first bib and display them as selectable options.

If the parent bib has multiple holdings, the user may choose which holding should be updated.

If no holding is explicitly selected, Boundwit Whiz uses the first holding returned by Alma, preserving the application's original behavior.

The selected holding ID should always be validated against the holdings belonging to the parent bib before it is used.

## SSO

The application uses OmniAuth SAML for Temple SSO.

The SAML request phase uses POST binding so authentication requests are accepted by the Temple IdP.

The callback is handled by `SessionsController#saml`.

After SAML authentication succeeds, the application retrieves the corresponding Alma user and verifies that the user has the `Cataloger` role before creating the Rails session.

## MARC record display

Updated records are shown from the local `MarcRecord` cache.

The success page provides a `view record` link for each bib and associated holding.

Records are displayed in a Stimulus-powered modal using standard MARC tags, indicators, and subfields.

The cached MARCXML is parsed back into a `MARC::Record` when displayed.

Cached records may be refreshed from Alma when a current authoritative copy is needed.

## Safety when developing

Development work may update real Alma records depending on the configured API key.

Before running a bound-with operation:

* Verify which Alma environment the API key targets.
* Prefer dedicated test records.
* Inspect generated MARC changes before testing against production data.
* Do not assume cached records are authoritative.
* Remember that Alma is always the source of truth.
* Be especially careful when modifying collection iteration or MARC field generation, since duplicate processing can produce duplicate fields in Alma.

## Useful commands

```bash
# Start development
bin/dev

# Rails console
bin/rails console

# Run all tests
bundle exec rspec

# Run one spec
bundle exec rspec spec/services/bound_with/updater_spec.rb

# Prepare database
bin/rails db:prepare

# Run migrations
bin/rails db:migrate

# Show routes
bin/rails routes
```

## Architecture

```text
Browser
  |
  v
BoundWithsController
  |
  v
BoundWith::Updater
  |
  +--> BoundWith::MarcEditor
  |
  +--> Alma API
  |
  +--> MarcRecord cache
```

Authentication follows a separate path:

```text
Browser
  |
  v
Temple SSO
  |
  v
OmniAuth SAML
  |
  v
SessionsController
  |
  +--> Alma::User
          |
          +--> Cataloger role check
```

## Contributing

Keep controllers thin and put domain behavior in the appropriate service or model.

When changing bound-with behavior:

1. Add or update the MARC editor spec.
2. Add regression coverage for the updater where appropriate.
3. Verify that records are not processed more than once.
4. Verify that the selected holding belongs to the parent bib.
5. Test against designated Alma test records before using the change with production data.

When changing an Alma override:

1. Test the behavior through the real overridden Alma class.
2. Add regression coverage for the specific behavior being fixed.
3. Avoid depending on undocumented behavior of the underlying gem where possible.
