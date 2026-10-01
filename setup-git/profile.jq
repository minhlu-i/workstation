def text: type == "string" and length > 0 and (explode | all(. >= 32 and . != 127));
def slug: type == "string" and test("^[a-z][a-z0-9-]*$");
def workspace:
  type == "string" and test("^[A-Za-z0-9 _./-]+$") and
  (startswith("/") | not) and (split("/") | all(. != "" and . != "." and . != ".."));
if (.version != 1 and .version != 2) or (.accounts | type != "object" or length == 0) then
  error("require version 1 or 2 and at least one account")
else . end |
.version as $version |
.accounts |= with_entries(
  .key as $id |
  if ($id | slug | not) or (.value | type != "object") then error("invalid account ID") else . end |
  .value |= (
    . + {workspace: (.workspace // ("Workspace/" + $id))} |
    if $version == 1 and (has("sshKeyItem") or has("privateKeyFile")) then
      . + {sshAlias: (.sshAlias // (if $id == "personal" then "gh-p" elif $id == "s5tech" then "gh-s5" else "gh-" + $id end))}
    else . end |
    {name, email, workspace} +
    (if has("sshKeyItem") or has("privateKeyFile") then
      {sshAlias: (.sshAlias // ("gh-" + $id))} +
      (if has("sshKeyItem") then {sshKeyItem} else {} end) +
      (if has("privateKeyFile") then {privateKeyFile} else {} end) +
      (if has("publicKeyFile") then {publicKeyFile} else {} end) +
      (if has("githubOwner") then {githubOwner} else {} end)
    elif has("githubOwner") or has("sshAlias") or has("publicKeyFile") then
      error("SSH fields require sshKeyItem or privateKeyFile")
    else {} end) |
    if ([.name, .email] | all(text)) and (.workspace | workspace) and
      (if has("sshAlias") then
        ($id != "config") and
        (.sshAlias | slug) and
        (if has("githubOwner") then (.githubOwner | type == "string" and test("^[A-Za-z0-9][A-Za-z0-9-]*$")) else true end) and
        (if has("sshKeyItem") then (.sshKeyItem | text) else true end) and
        (if has("privateKeyFile") then (.privateKeyFile | text) else true end) and
        (if has("publicKeyFile") then (.publicKeyFile | text) else true end)
      else true end)
    then . else error("invalid identity, workspace or SSH fields") end
  )
) |
.version = 2 |
[.accounts[].workspace] as $paths |
if ([$paths[] as $a | $paths[] as $b | select($a != $b and ($a | startswith($b + "/")))] | length > 0) or
   ($paths | unique | length != ($paths | length)) or
   ([.accounts[] | .sshAlias? // empty] | length != (unique | length)) or
   ([.accounts[] | .githubOwner? // empty | ascii_downcase] | length != (unique | length)) then
  error("overlapping workspaces, duplicate SSH aliases or owners")
else {version, accounts} end
