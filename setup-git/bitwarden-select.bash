# List metadata only, then collect configuration for explicitly selected key IDs.
select_bitwarden_keys() {
    [[ $no_input == 0 ]] || fail 'Key selection requires input; use --profile-item or --refresh with saved item IDs for --no-input.'
    if ! bw list items 2>/dev/null | jq -e '
        if type != "array" then error("invalid item list") else . end |
        [.[] | select(.type == 5 and (.deletedDate? == null)) |
         {id, name: (.name // "SSH key" | gsub("[[:cntrl:]]"; " "))}] |
        sort_by(.name, .id) |
        if all(.id | type == "string" and test("^[A-Za-z0-9][A-Za-z0-9-]*$")) and
           (map(.id) | length == (unique | length)) then . else error("invalid item IDs") end
    ' > "$work/key-list.json" 2>/dev/null; then
        fail 'Cannot list Bitwarden SSH keys.'
    fi
    local count selection numbers number item_id name account base suffix username email workspace previous_name previous_owner
    count=$(jq length "$work/key-list.json")
    printf 'Found %s SSH key item(s) in Bitwarden.\n' "$count"
    [[ $count -gt 0 ]] || fail 'No SSH key items found; create/import a key in Bitwarden first.'
    if [[ -t 0 ]]; then
        source "$module/key-selector.bash"
        numbers=$(checkbox_keys "$work/key-list.json") || fail 'No SSH keys selected; no configuration deployed.'
    else
        # Piped input supports scripted fixtures; terminal users get checkboxes.
        jq -r 'to_entries[] | "\(.key + 1). \(.value.name) [\(.value.id)]"' "$work/key-list.json"
        read -r -p 'Select key numbers (e.g. 1 2, or all; q cancels): ' selection || fail 'No SSH keys selected; no configuration deployed.'
        [[ -n $selection && $selection != q && $selection != cancel ]] || fail 'No SSH keys selected; no configuration deployed.'
        if [[ $selection == all ]]; then
            numbers=$(jq -c '[range(1; length + 1)]' "$work/key-list.json")
        else
            numbers=$(jq -cn -e --arg selection "$selection" --argjson count "$count" '
              if ($selection | test("^[0-9]+([ ,]+[0-9]+)*$")) then
                ($selection | gsub(","; " ") | split(" ") | map(select(length > 0) | tonumber)) |
                if all(. >= 1 and . <= $count and floor == .) and (length == (unique | length)) then .
                else error("invalid selection") end
              else error("invalid selection") end' 2>/dev/null) || fail 'Invalid key selection; choose distinct numbers from the list.'
        fi
    fi
    if [[ -f $work/previous.json ]]; then cp "$work/previous.json" "$work/selection-profile.json";
    else printf '{"version":2,"accounts":{}}\n' > "$work/selection-profile.json"; fi
    : > "$work/selected-accounts"
    for number in $(printf '%s' "$numbers" | jq -r '.[]'); do
        item_id=$(jq -r --argjson number "$number" '.[$number - 1].id' "$work/key-list.json")
        name=$(jq -r --argjson number "$number" '.[$number - 1].name' "$work/key-list.json")
        account=$(jq -r --arg id "$item_id" --arg name "$name" --slurpfile list "$work/key-list.json" '
          .accounts | to_entries | map(select(.value.sshKeyItem == $id or
          (.value.sshKeyItem == $name and ([$list[0][] | select(.name == $name)] | length) == 1))) |
          .[0].key // empty' "$work/selection-profile.json")
        if [[ -z $account ]]; then
            base=$(printf '%s' "$name" | jq -Rr 'ascii_downcase | gsub("[^a-z0-9]+"; "-") | gsub("^-|-$"; "") | if . == "" then "key" elif test("^[a-z]") then . else "key-" + . end | if . == "config" then "key-config" else . end')
            account=$base; suffix=2
            while jq -e --arg id "$account" '.accounts | has($id)' "$work/selection-profile.json" >/dev/null; do
                account="$base-$suffix"; suffix=$((suffix + 1))
            done
        fi
        previous_name=$(field "$work/selection-profile.json" "$account" name)
        previous_owner=$(field "$work/selection-profile.json" "$account" githubOwner)
        email=$(field "$work/selection-profile.json" "$account" email)
        workspace=$(field "$work/selection-profile.json" "$account" workspace)
        workspace=${workspace:-Workspace/$account}
        printf '\nKey: %s; account: %s\n' "$name" "$account"
        read -r -p "GitHub username${previous_owner:+ [$previous_owner]}: " username || fail 'GitHub username input cancelled.'
        username=${username:-$previous_owner}
        local entered_email entered_workspace entered_name author_name default_name
        read -r -p "Git email${email:+ [$email]}: " entered_email || fail 'Git email input cancelled.'
        email=${entered_email:-$email}
        default_name=${previous_name:-$username}
        read -r -p "Git author name [$default_name]: " entered_name || fail 'Git author name input cancelled.'
        author_name=${entered_name:-$default_name}
        read -r -p "Workspace relative to HOME [$workspace]: " entered_workspace || fail 'Workspace input cancelled.'
        workspace=${entered_workspace:-$workspace}
        jq --arg account "$account" --arg name "$author_name" --arg email "$email" \
            --arg workspace "$workspace" --arg item "$item_id" --arg owner "$username" '
            .accounts[$account] = {name:$name,email:$email,workspace:$workspace,sshKeyItem:$item,
              sshAlias:(.accounts[$account].sshAlias // ("gh-" + $account)),githubOwner:$owner}
        ' "$work/selection-profile.json" > "$work/next-profile.json"
        mv "$work/next-profile.json" "$work/selection-profile.json"
        printf '%s\n' "$account" >> "$work/selected-accounts"
    done
    normalize_profile "$work/selection-profile.json" "$work/profile.json"
    create_workspaces=1
}
