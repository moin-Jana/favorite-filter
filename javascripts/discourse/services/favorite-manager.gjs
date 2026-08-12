import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

const USERFIELD_ID = Number(settings.custom_user_field_ID);
const STORAGE_KEY = "filterFavorites";

function parseFavorites(str) {
  if (!str) {
    return [];
  }
  return str.split(";;").map((entry) => {
    const [label, query, icon, emoji] = entry.split("||");
    let styleType = "none";
    if (emoji) {
      styleType = "emoji";
    } else if (icon) {
      styleType = "icon";
    }
    return {
      label,
      query,
      icon: icon || undefined,
      emoji: emoji || undefined,
      styleType,
    };
  });
}

function stringifyFavorites(favs) {
  return favs
    .map((f) => [f.label, f.query, f.icon || "", f.emoji || ""].join("||"))
    .join(";;");
}

export default class FavoriteManager extends Service {
  @service currentUser;

  @tracked favorites = [];

  _loading = false;

  get allowedToCustomizeFilters() {
    if (!this.currentUser || USERFIELD_ID === 0) {
      return false;
    }

    return settings.user_in_custom_favorite_filters_allowed_groups;
  }

  get allowedToLoadDefaultFilters() {
    return settings.user_in_default_favorite_filters_groups;
  }

  async loadFavorites() {
    if (this._loading) {
      return;
    }

    this._loading = true;

    try {
      let favString = window.localStorage.getItem(STORAGE_KEY) || "";
      this.favorites = parseFavorites(favString);

      let serverString = "";

      if (this.allowedToCustomizeFilters) {
        const result = await ajax(`/u/${this.currentUser.username}.json`);
        serverString = result.user.user_fields[USERFIELD_ID] || "";

        if (serverString && serverString !== favString) {
          window.localStorage.setItem(STORAGE_KEY, serverString);
          this.favorites = parseFavorites(serverString);
          favString = serverString;
        }
      } else {
        localStorage.removeItem(STORAGE_KEY);
        this.favorites = [];
      }

      const defaultString = settings.default_favorites || "";

      if (
        this.allowedToLoadDefaultFilters &&
        !serverString &&
        defaultString &&
        (!favString || defaultString !== favString)
      ) {
        window.localStorage.setItem(STORAGE_KEY, defaultString);
        this.favorites = parseFavorites(defaultString);
      }
    } finally {
      this._loading = false;
    }
  }

  async persistFavorites(newFavorites) {
    const favString = stringifyFavorites(newFavorites);
    if (favString.length > 2048) {
      return { success: false, reason: "too_long" };
    }

    if (this.currentUser) {
      try {
        await ajax(`/u/${this.currentUser.username}.json`, {
          type: "PUT",
          data: { user_fields: { [USERFIELD_ID]: favString } },
        });
      } catch (e) {
        // eslint-disable-next-line no-console
        console.error("Failed to save favorites to custom user field: ", e);
        return { success: false, reason: "unknown" };
      }
    }
    this.favorites = [...newFavorites];
    window.localStorage.setItem(STORAGE_KEY, favString);

    return { success: true };
  }

  get defaultFavorites() {
    if (!this.allowedToLoadDefaultFilters) {
      return [];
    }
    return parseFavorites(settings.default_favorites || "");
  }

  resetToDefaults() {
    this.favorites = this.defaultFavorites;
  }
}
