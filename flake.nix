{
    inputs = { } ;
    outputs =
        { self } :
            {
                lib =
                    {
                        config-identity ? x : x ,
                        implementation-identity ? x : x ,
                        lib-identity ? x : x ,
                        pkgs-identity ? x : x
                     } :
                        let
                            implementation =
                                { config , lib , pkgs , ... } :
                                    let
                                        _config = config-identity config ;
                                        _lib = lib-identity lib ;
                                        _pkgs = pkgs-identity pkgs ;
                                        in
                                        implementation-identity
                                            {
                                                options.node-package =
                                                    {
                                                        build =
                                                            _lib.mkOption
                                                                {
                                                                    default =
                                                                        input :
                                                                            _pkgs.runCommand
                                                                                "build"
                                                                                {
                                                                                    nativeBuildInputs =
                                                                                        [
                                                                                            (
                                                                                                _pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "build" ;
                                                                                                        runtimeInputs =
                                                                                                            [
                                                                                                                _pkgs.coreutils
                                                                                                                _pkgs.findutils
                                                                                                                _pkgs.nodejs
                                                                                                                (
                                                                                                                    _pkgs.writeShellApplication
                                                                                                                        {
                                                                                                                            name = "implode" ;
                                                                                                                            runtimeInputs =
                                                                                                                                [
                                                                                                                                    _pkgs.coreutils
                                                                                                                                    _pkgs.findutils
                                                                                                                                    _pkgs.jq
                                                                                                                                    ( _config.failure { } )
                                                                                                                                ] ;
                                                                                                                            text =
                                                                                                                                ''
                                                                                                                                    RELATIVE_INPUT_FILE="$1"
                                                                                                                                    OUT="$2"
                                                                                                                                    PERMISSIONS="$( jq --raw-output ".permissions" "$RELATIVE_INPUT_FILE/metadata.json" )" || failure 3808418135747408
                                                                                                                                    TAG="$( jq --raw-output ".tag" "$RELATIVE_INPUT_FILE/metadata.json" )" || failure 2878641484898157
                                                                                                                                    TYPE="$( jq --raw-output ".type" "$RELATIVE_INPUT_FILE/metadata.json" )" || failure 1111350995632152
                                                                                                                                    RELATIVE_OUTPUT_FILE="$OUT/node_modules/$TAG"
                                                                                                                                    RELATIVE_OUTPUT_DIRECTORY="$( dirname "$RELATIVE_OUTPUT_FILE" )" || failure 9352183167901733
                                                                                                                                    mkdir --parents "$RELATIVE_OUTPUT_DIRECTORY"
                                                                                                                                    if [[ "$TYPE" == "directory" ]]
                                                                                                                                    then
                                                                                                                                        mkdir --parents "$RELATIVE_OUTPUT_FILE"
                                                                                                                                    elif [[ "$TYPE" == "regular file" ]]
                                                                                                                                    then
                                                                                                                                        cat "$TAG"/parts/* > "$RELATIVE_OUTPUT_FILE"
                                                                                                                                    else
                                                                                                                                        failure 1129645981666929 "$RELATIVE_INPUT_FILE" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                                                    fi
                                                                                                                                    chmod "$PERMISSIONS" "$RELATIVE_OUTPUT_FILE"
                                                                                                                                '' ;
                                                                                                                        }
                                                                                                                )
                                                                                                            ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                OUT="$1"
                                                                                                                mkdir --parents "$OUT"
                                                                                                                cp --recursive ${ input }/. "$OUT"
                                                                                                                cd ${ input }
                                                                                                                find node_modules.exploded -mindepth 1 -maxdepth 1 -exec implode {} "$OUT" \;
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                                    }
                                                                                    ''
                                                                                        build "$out"
                                                                                    '' ;
                                                                    type = _lib.types.functionTo _lib.types.package ;
                                                                } ;
                                                        execute =
                                                            lib.mkOption
                                                                {
                                                                    default =
                                                                        { command , name , package , work-directory } :
                                                                            _pkgs.writeShellApplication
                                                                                {
                                                                                    name = name ;
                                                                                    runtimeInputs = [ _pkgs.nodejs ] ;
                                                                                    text =
                                                                                        ''
                                                                                            # PATH=/home/emory/.nix-profile/bin:/nix/profile/bin:"$PATH"
                                                                                            PATH="$PATH":/run/current-system/sw/bin:/home/emory/.nix-profile/bin:/nix/profile/bin
                                                                                            WORK_DIR="$( mktemp --directory )"
                                                                                            # mkdir --parents ${ work-directory }
                                                                                            cp --recursive ${ package }/. "$WORK_DIR"
                                                                                            cd "$WORK_DIR"
                                                                                            pwd
                                                                                            ls -lah .
                                                                                            npm ${ command }
                                                                                        '' ;
                                                                                } ;
                                                                    type = _lib.types.functionTo _lib.types.package ;
                                                                } ;
                                                        fetch =
                                                            _lib.mkOption
                                                                {
                                                                    default =
                                                                        package :
                                                                            _pkgs.writeShellApplication
                                                                                {
                                                                                    name = "fetch" ;
                                                                                    runtimeInputs =
                                                                                        [
                                                                                            _pkgs.coreutils
                                                                                            _pkgs.git
                                                                                            _pkgs.nodejs_20
                                                                                            (
                                                                                                _pkgs.writeShellApplication
                                                                                                    {
                                                                                                        name = "explode" ;
                                                                                                        runtimeInputs =
                                                                                                            [
                                                                                                                _pkgs.coreutils
                                                                                                                _pkgs.git
                                                                                                                _pkgs.jq
                                                                                                                ( _config.failure { } )
                                                                                                            ] ;
                                                                                                        text =
                                                                                                            ''
                                                                                                                RELATIVE_INPUT_FILE="$1"
                                                                                                                ABSOLUTE_INPUT_FILE="$( realpath "$RELATIVE_INPUT_FILE" )" || failure 7861779372817123
                                                                                                                TAG="${ "$" }{RELATIVE_INPUT_FILE#node_modules/}"
                                                                                                                HASH="$( echo "$TAG" | sha512sum | cut --characters 1-128 )" || failure 3652604998111458
                                                                                                                RELATIVE_OUTPUT_FILE="node_modules.exploded/$HASH"
                                                                                                                PERMISSIONS="$( stat --printf %a "$ABSOLUTE_INPUT_FILE" )" || failure 9035064744130892
                                                                                                                TYPE="$( stat --printf %F "$ABSOLUTE_INPUT_FILE" )" || failure 9216061067032392
                                                                                                                if [[ -d "$RELATIVE_OUTPUT_FILE" ]]
                                                                                                                then
                                                                                                                    failure 0701446510561736 "$HASH" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                                else
                                                                                                                    mkdir --parents "$RELATIVE_OUTPUT_FILE"
                                                                                                                fi
                                                                                                                cd "$RELATIVE_OUTPUT_FILE"
                                                                                                                jq \
                                                                                                                    --null-input \
                                                                                                                    --arg PERMISSIONS "$PERMISSIONS" \
                                                                                                                    --arg TAG "$TAG" \
                                                                                                                    --arg TYPE "$TYPE" \
                                                                                                                    '{
                                                                                                                        "permissions" : $PERMISSIONS ,
                                                                                                                        "tag" : $TAG ,
                                                                                                                        "type" : $TYPE
                                                                                                                    }' > metadata.json
                                                                                                                if [[ -d "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                                then
                                                                                                                    :
                                                                                                                elif [[ -f "$ABSOLUTE_INPUT_FILE" ]]
                                                                                                                then
                                                                                                                    mkdir parts
                                                                                                                    cd parts
                                                                                                                    split --bytes 1M "$ABSOLUTE_INPUT_FILE"
                                                                                                                else
                                                                                                                    failure 9059723240083957 "$ABSOLUTE_INPUT_FILE" "$PERMISSIONS" "$TAG" "$TYPE"
                                                                                                                fi
                                                                                                                git add .
                                                                                                            '' ;
                                                                                                    }
                                                                                            )
                                                                                        ] ;
                                                                                    text =
                                                                                        ''
                                                                                            MESSAGE="$1"
                                                                                            cat ${ builtins.toFile "package.json" ( builtins.toJSON package ) } > "package.json"
                                                                                            git add package.json
                                                                                            git rm --recursive --ignore-unmatch node_modules.exploded
                                                                                            npm install
                                                                                            find node_modules -exec explode {} \;
                                                                                            git clean -fd
                                                                                            git commit -m "$MESSAGE" --allow-empty --allow-empty-message
                                                                                        '' ;
                                                                                } ;
                                                                    type = _lib.types.functionTo _lib.types.package ;
                                                                } ;
                                                    } ;
                                    } ;
                            in
                                {
                                    check = null ;
                                    implementation = implementation ;
                                } ;
            } ;
}
