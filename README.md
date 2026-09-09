# Boundwit Whiz

Boundwit Whiz is a Rails application for creating and maintaining bound-with relationships in Alma.

The application accepts a list of Alma MMS IDs, treats the first bibliographic record as the parent, and updates the related MARC bibliographic and holding records so the titles are represented as a bound-with set.

## What it does

Given a list of MMS IDs, Boundwit Whiz:

* Treats the first bib as the parent record.
* Retrieves the holdings associated with the parent bib.
* Automatically uses the parent holding when there is only one.
* Prompts the cataloger to select a holding when the parent has multiple holdings.
* Adds `774` fields to the parent for each child bib.
* Adds a `773` field to each child pointing back to the parent.
* Adds a `501` "Bound with:" note to each bib describing the other titles in the set.
* Adds `014` fields to the selected parent holding for the related MMS IDs.
* Updates the records in Alma.
* Caches the updated MARC records locally so they can be displayed without making another Alma API request.

Alma remains the source of truth.

## Requirements

* Ruby
* Rails
* SQLite for local development
* Access to the Alma API
* Temple SSO configuration when authentication is enabled

Install dependencies:

```bash
bundle install
```

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

### BoundWith::Preparation

`BoundWith::Preparation` prepares a bound-with operation before any MARC records are updated.

It is responsible for:

1. Retrieving the supplied bib records from Alma.
2. Treating the first bib as the parent.
3. Retrieving the holdings associated with the parent bib.
4. Raising an error if the parent has no holdings.
5. Caching the retrieved bib records locally.
6. Determining whether the cataloger needs to select a holding.
7. Retrieving and caching the parent holding automatically when only one holding exists.

When the parent has multiple holdings, preparation stops before any Alma updates are made and the controller renders the holding-selection page.

### BoundWith::Updater

`BoundWith::Updater` performs the actual bound-with update after the bibs and parent holding have been resolved.

It receives:

```ruby
BoundWith::Updater.new(
  bibs: bibs,
  holding: holding
).call
```

It is responsible for:

1. Removing previously generated bound-with MARC fields.
2. Adding the appropriate `501`, `773`, `774`, and `014` fields.
3. Updating the bib records in Alma.
4. Updating the selected parent holding in Alma.
5. Caching the successfully updated MARC records locally.

Record retrieval and holding selection belong in `BoundWith::Preparation`, while MARC-specific manipulation belongs in `BoundWith::MarcEditor`.

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
* Caching Alma bib and holding records locally.
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

Cached `MarcRecord` objects can also be converted back into Alma bib and holding objects when records need to be carried between steps of the bound-with workflow.

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

### Step 1: Enter MMS IDs

The cataloger enters two or more MMS IDs, one per line.

The first MMS ID identifies the parent bib. The remaining MMS IDs identify the child bibs.

The application validates the submitted MMS IDs before beginning the bound-with operation.

### Step 2: Prepare the records

`BoundWith::Preparation` retrieves the bibs from Alma and retrieves the holdings belonging to the parent bib.

If the parent has no holdings, the operation stops with an error.

If the parent has exactly one holding, that holding is automatically selected and the application proceeds directly to the update.

### Step 3: Select a holding when necessary

If the parent bib has multiple holdings, the application displays a holding-selection page before making any bound-with changes.

Each available holding is identified by:

* Library
* Location
* Call number
* Holding ID

The cataloger selects the holding representing the physical bound volume and submits the form.

The MMS IDs are carried forward to the second request so the same set of bib records can be used to finish the operation.

### Step 4: Update Alma

Once the holding has been resolved, `BoundWith::Updater` modifies the MARC records.

For the parent bib:

* Existing generated bound-with fields are removed.
* A `501` note describing the bound-with set is added.
* A `774` field is added for each child bib.

For each child bib:

* Existing generated bound-with fields are removed.
* A `501` note describing the bound-with set is added.
* A `773` field pointing to the parent is added.

For the selected parent holding:

* Existing generated bound-with fields are removed.
* An `014` field is added for each child bib.

The changed bibs and selected holding are then written back to Alma.

### Step 5: Display the result

After Alma has been updated successfully, the changed MARC records are cached locally and the user is redirected to the success page.

The success page displays the bib records and associated holding from the local `MarcRecord` cache.

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

## Safety when developing

Development work may update real Alma records depending on the configured API key.

Before running a bound-with operation:

* Verify which Alma environment the API key targets.
* Prefer dedicated test records.
* Inspect generated MARC changes before testing against production data.
* Do not assume cached records are authoritative.
* Remember that Alma is always the source of truth.
* Confirm that the selected holding represents the intended physical bound volume.
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

A bound-with operation now has a preparation phase followed by an update phase:

```text
Browser
  |
  v
BoundWithsController
  |
  v
BoundWith::Preparation
  |
  +--> Alma API
  |
  +--> MarcRecord cache
  |
  +--> one holding -------------------------+
  |                                         |
  +--> multiple holdings                    |
          |                                 |
          v                                 |
     Holding Selection                      |
          |                                 |
          +---------------------------------+
                                            |
                                            v
                                  BoundWith::Updater
                                            |
                              +-------------+-------------+
                              |                           |
                              v                           v
                    BoundWith::MarcEditor              Alma API
                                                          |
                                                          v
                                                  MarcRecord cache
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
2. Add regression coverage for `BoundWith::Preparation` when changing record retrieval or holding-selection behavior.
3. Add regression coverage for `BoundWith::Updater` when changing the Alma update workflow.
4. Verify that records are not processed more than once.
5. Test the zero-, one-, and multiple-holding cases when changing holding behavior.
6. Test against designated Alma test records before using the change with production data.

When changing an Alma override:

1. Test the behavior through the real overridden Alma class.
2. Add regression coverage for the specific behavior being fixed.
3. Avoid depending on undocumented behavior of the underlying gem where possible.
