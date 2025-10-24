import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { Input } from "@ember/component";
import { fn, hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { eq, or } from "truth-helpers";
import DButton from "discourse/components/d-button";
import DModal from "discourse/components/d-modal";
import EmojiPicker from "discourse/components/emoji-picker";
import RadioButton from "discourse/components/radio-button";
import icon from "discourse/helpers/d-icon";
import emoji from "discourse/helpers/emoji";
import { i18n } from "discourse-i18n";
import IconPicker from "select-kit/components/icon-picker";

class EditableFavorite {
  @tracked label;
  @tracked query;
  @tracked icon;
  @tracked emoji;
  @tracked styleType;

  @tracked uiIcon;

  @tracked validationErrorLabel = null;
  @tracked validationErrorQuery = null;

  constructor(fav) {
    this.label = fav.label;
    this.query = fav.query;
    this.icon = fav.icon;
    this.emoji = fav.emoji;
    this.styleType =
      fav.styleType || (fav.emoji ? "emoji" : fav.icon ? "icon" : "none");
    this.uiIcon = fav.icon;
  }

  commitUI() {
    this.icon = this.uiIcon;
  }

  toJSON() {
    const result = {
      label: this.label,
      query: this.query,
      styleType: this.styleType,
    };
    if (this.styleType === "icon") {
      result.icon = this.icon;
    }
    if (this.styleType === "emoji") {
      result.emoji = this.emoji;
    }
    return result;
  }
}

export default class FFEditLinkModal extends Component {
  @service favoriteManager;
  @service dialog;

  @tracked favorites = [];
  @tracked expandedIndex = null;

  constructor() {
    super(...arguments);
    this.favorites = (this.favoriteManager.favorites || []).map(
      (fav) => new EditableFavorite(fav)
    );
  }

  @action
  toggleExpanded(idx) {
    this.expandedIndex = this.expandedIndex === idx ? null : idx;
  }

  @action
  moveFavorite(idx, direction) {
    const newFavs = [...this.favorites];
    const newIndex = idx + direction;
    if (newIndex < 0 || newIndex >= newFavs.length) {
      return;
    }

    const [moved] = newFavs.splice(idx, 1);
    newFavs.splice(newIndex, 0, moved);
    this.favorites = newFavs;
  }

  @action
  deleteFavorite(idx) {
    this.favorites = this.favorites.filter((_, i) => i !== idx);
  }

  @action
  updateField(idx, field, event) {
    const value = event?.target?.value ?? event;
    const fav = this.favorites[idx];
    if (!fav) {
      return;
    }

    fav[field] = value;

    if (field === "label" && fav.validationErrorLabel && value?.trim()) {
      fav.validationErrorLabel = null;
    }
    if (field === "query" && fav.validationErrorQuery && value?.trim()) {
      fav.validationErrorQuery = null;
    }

    this.favorites = [...this.favorites];
  }

  @action
  async saveAll() {
    let hasError = false;
    let firstInvalidIndex = null;

    this.favorites.forEach((f, idx) => {
      let labelInvalid = !f.label?.trim();
      let queryInvalid = !f.query?.trim();

      f.validationErrorLabel = labelInvalid
        ? "modal.error.title_required"
        : null;
      f.validationErrorQuery = queryInvalid
        ? "modal.error.query_required"
        : null;

      if (labelInvalid || queryInvalid) {
        hasError = true;
        if (firstInvalidIndex === null) {
          firstInvalidIndex = idx;
        }
      }
    });

    if (hasError) {
      this.expandedIndex = firstInvalidIndex;
      this.favorites = [...this.favorites];
      return;
    }

    this.favorites.forEach((f) => f?.commitUI?.());

    const serialized = this.favorites.map((f) => f.toJSON());
    const result = await this.favoriteManager.persistFavorites(serialized);

    if (result.success) {
      this.args.closeModal?.();
    } else if (result.reason === "too_long") {
      this.dialog.alert({
        title: i18n(themePrefix("modal.error.too_long_title")),
        message: i18n(themePrefix("modal.error.too_long_message")),
      });
    } else {
      this.dialog.alert({
        message: i18n(themePrefix("modal.error.general_message")),
      });
    }
  }

  @action
  resetToDefault() {
    this.favorites = this.favoriteManager.defaultFavorites.map(
      (f) => new EditableFavorite(f)
    );
  }

  get numOfFavsMinusOne() {
    return this.favorites.length - 1;
  }

  <template>
    <DModal
      @title={{i18n (themePrefix "modal.title.edit_fav")}}
      @closeModal={{@closeModal}}
      class="ff-modal edit-link-modal"
    >
      <:body>
        <div class="ff-edit-links">
          {{#each this.favorites as |fav idx|}}
            <div
              class="fav-entry
                {{if (eq idx this.expandedIndex) 'expanded'}}
                {{if
                  (or fav.validationErrorLabel fav.validationErrorQuery)
                  'has-error'
                }}"
            >
              <div class="order-btns">
                <DButton
                  @icon="arrow-up"
                  @action={{fn this.moveFavorite idx -1}}
                  @disabled={{eq idx 0}}
                  @translatedTitle={{i18n
                    (themePrefix "modal.move_up")
                    label=fav.label
                  }}
                  @translatedAriaLabel={{i18n
                    (themePrefix "modal.move_up")
                    label=fav.label
                  }}
                  class="btn-ff"
                />
                <DButton
                  @icon="arrow-down"
                  @action={{fn this.moveFavorite idx 1}}
                  @disabled={{eq idx this.numOfFavsMinusOne}}
                  @translatedTitle={{i18n
                    (themePrefix "modal.move_down")
                    label=fav.label
                  }}
                  @translatedAriaLabel={{i18n
                    (themePrefix "modal.move_down")
                    label=fav.label
                  }}
                  class="btn-ff"
                />
              </div>

              <div class="fav-entry-content">
                <div class="fav-header">
                  <span class="symbol-title">
                    {{#if (eq fav.styleType "emoji")}}
                      {{#if fav.emoji}}
                        {{emoji fav.emoji}}
                      {{/if}}
                    {{else if (eq fav.styleType "icon")}}
                      {{#if fav.uiIcon}}
                        {{icon fav.uiIcon}}
                      {{/if}}
                    {{/if}}
                    <span class="fav-title">{{fav.label}}</span>
                  </span>

                  <span class="fav-actions">
                    <DButton
                      @icon={{if
                        (eq idx this.expandedIndex)
                        "chevron-up"
                        "pencil"
                      }}
                      @action={{fn this.toggleExpanded idx}}
                      @translatedTitle={{i18n
                        (themePrefix "modal.edit")
                        label=fav.label
                      }}
                      @translatedAriaLabel={{i18n
                        (themePrefix "modal.edit")
                        label=fav.label
                      }}
                      class="btn-ff"
                    />
                    <DButton
                      @icon="trash-can"
                      @action={{fn this.deleteFavorite idx}}
                      @translatedTitle={{i18n
                        (themePrefix "modal.delete")
                        label=fav.label
                      }}
                      @translatedAriaLabel={{i18n
                        (themePrefix "modal.delete")
                        label=fav.label
                      }}
                      class="btn-ff"
                    />
                  </span>
                </div>

                {{#if (eq idx this.expandedIndex)}}
                  <div class="favorite-details">

                    <div class="form-group">
                      <div class="label-row">
                        <label>{{i18n
                            (themePrefix "modal.title_label")
                          }}</label>
                        {{#if fav.validationErrorLabel}}
                          <div class="input-error">
                            {{icon "xmark"}}
                            {{i18n (themePrefix fav.validationErrorLabel)}}
                          </div>
                        {{/if}}
                      </div>
                      <Input
                        @value={{fav.label}}
                        {{on "input" (fn this.updateField idx "label")}}
                        class="form-control"
                        aria-invalid={{if
                          fav.validationErrorLabel
                          "true"
                          "false"
                        }}
                      />
                    </div>

                    <div class="form-group">
                      <div class="label-row">
                        <label>{{i18n
                            (themePrefix "modal.query_label")
                          }}</label>
                        {{#if fav.validationErrorQuery}}
                          <div class="input-error">
                            {{icon "xmark"}}
                            {{i18n (themePrefix fav.validationErrorQuery)}}
                          </div>
                        {{/if}}
                      </div>
                      <Input
                        @value={{fav.query}}
                        {{on "input" (fn this.updateField idx "query")}}
                        class="form-control"
                        aria-invalid={{if
                          fav.validationErrorQuery
                          "true"
                          "false"
                        }}
                      />
                    </div>

                    <div class="form-group symbol-type-group">
                      <label>{{i18n
                          (themePrefix "modal.symbol_type_label")
                        }}</label>
                      <div class="symbol-type-layout">
                        <div class="symbol-type-options">
                          <label class="radio-option">
                            <RadioButton
                              @value="icon"
                              @selection={{fav.styleType}}
                              {{on
                                "change"
                                (fn this.updateField idx "styleType" "icon")
                              }}
                            />
                            {{i18n (themePrefix "modal.symbolType.icon")}}
                          </label>
                          <label class="radio-option">
                            <RadioButton
                              @value="emoji"
                              @selection={{fav.styleType}}
                              {{on
                                "change"
                                (fn this.updateField idx "styleType" "emoji")
                              }}
                            />
                            {{i18n (themePrefix "modal.symbolType.emoji")}}
                          </label>
                          <label class="radio-option">
                            <RadioButton
                              @value="none"
                              @selection={{fav.styleType}}
                              {{on
                                "change"
                                (fn this.updateField idx "styleType" "none")
                              }}
                            />
                            {{i18n (themePrefix "modal.symbolType.none")}}
                          </label>
                        </div>

                        <div class="symbol-type-picker">
                          {{#if (eq fav.styleType "icon")}}
                            <IconPicker
                              @value={{fav.uiIcon}}
                              @onChange={{fn this.updateField idx "uiIcon"}}
                              @onlyAvailable={{true}}
                              @options={{hash maximum=1 icons=fav.uiIcon}}
                              aria-label={{i18n
                                (themePrefix "modal.choose_icon_label")
                              }}
                            />
                          {{else if (eq fav.styleType "emoji")}}
                            <EmojiPicker
                              @emoji={{fav.emoji}}
                              @modalForMobile={{false}}
                              @didSelectEmoji={{fn
                                this.updateField
                                idx
                                "emoji"
                              }}
                              @btnClass="btn-emoji"
                              @context="favorite-filter"
                              aria-label={{i18n
                                (themePrefix "modal.choose_emoji_label")
                              }}
                            />
                          {{/if}}
                        </div>
                      </div>
                    </div>
                  </div>
                {{/if}}
              </div>
            </div>
          {{/each}}
        </div>
      </:body>

      <:footer>
        <div class="btn-left">
          <DButton
            @icon="floppy-disk"
            @translatedLabel={{i18n (themePrefix "modal.save_btn")}}
            @action={{this.saveAll}}
            class="btn-primary"
          />
          <DButton
            @translatedLabel={{i18n (themePrefix "modal.cancel_btn")}}
            @action={{@closeModal}}
            class="btn-flat"
          />
        </div>
        <div class="btn-right">
          <DButton
            @icon="arrow-rotate-left"
            @translatedLabel={{i18n (themePrefix "modal.reset_btn")}}
            @action={{this.resetToDefault}}
            class="btn-flat reset-btn"
          />
        </div>
      </:footer>
    </DModal>
  </template>
}
