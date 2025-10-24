import { tracked } from "@glimmer/tracking";
import Service, { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";
import { AUTO_GROUPS } from "discourse/lib/constants";

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

  get allowedToCustomizeFilters() {
    if (!this.currentUser || USERFIELD_ID === 0) {
      return false;
    }

    const rawSetting =
      settings.custom_favorite_filters_allowed_groups?.trim() || "";

    const everyoneAllowed = rawSetting.split("|").includes("0");

    if (everyoneAllowed) {
      return true;
    }

    const allowedGroupIds = rawSetting
      .split("|")
      .map(Number)
      .filter((id) => id > 0);

    const currentUserGroupIds = this.currentUser.groups.map((g) => g.id);

    return allowedGroupIds.some((id) => currentUserGroupIds.includes(id));
  }

  get allowedToLoadDefaultFilters() {
    if (!settings.default_favorite_filters_groups) {
      return false;
    }

    const allowedGroupIds = settings.default_favorite_filters_groups
      .split("|")
      .map(Number);

    if (allowedGroupIds.includes(AUTO_GROUPS.everyone.id)) {
      return true;
    }

    if (this.currentUser) {
      const currentUserGroupIds = this.currentUser.groups.map((g) => g.id);
      return allowedGroupIds.some((id) => currentUserGroupIds.includes(id));
    }

    return false;
  }

  async loadFavorites() {
    let favString = window.localStorage.getItem(STORAGE_KEY) || "";
    this.favorites = parseFavorites(favString);

    let serverString = "";
    if (this.allowedToCustomizeFilters) {
      try {
        const result = await ajax(`/u/${this.currentUser.username}.json`);
        serverString = result.user.user_fields[USERFIELD_ID] || "";

        if (serverString && serverString !== favString) {
          window.localStorage.setItem(STORAGE_KEY, serverString);
          this.favorites = parseFavorites(serverString);
          favString = serverString;
        }
      } catch (e) {
        // eslint-disable-next-line no-console
        console.warn("Failed to parse favorites from stored string: ", e);
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
    return parseFavorites(settings.default_favorites || "");
  }

  resetToDefaults() {
    this.favorites = this.defaultFavorites;
  }
}
