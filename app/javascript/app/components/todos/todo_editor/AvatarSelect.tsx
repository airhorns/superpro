import React from "react";
import { find } from "lodash";
import ReactSelect from "react-select";
import { Box, Drop, Button } from "grommet";
import { UserCardProps, UserAvatar, UserCard } from "app/components/common";
import { Question } from "app/components/common/FlurishIcons";
import { FlurishReactSelectTheme, isArrayOptionType } from "flurishlib";
import { ValueType } from "react-select/lib/types";

export interface AvatarSelectProps {
  value: null | string;
  onChange: (value: null | string) => void;
  users: UserCardProps["user"][];
}

export const AvatarSelect = (props: AvatarSelectProps) => {
  const [open, setOpen] = React.useState(false);
  const buttonRef = React.useRef();
  const options = React.useMemo(
    () =>
      props.users.map(user => ({
        value: user.id,
        label: <UserCard user={user} />
      })),
    [props.users]
  );

  let selectedUser = null;
  let selectedOption = null;
  if (props.value) {
    selectedUser = find(props.users, { id: props.value });
    selectedOption = find(options, { value: props.value });
  }

  return (
    <>
      <Button ref={buttonRef as any} onClick={() => setOpen(true)}>
        {selectedUser && <UserAvatar user={selectedUser} size={24} />}
        {!selectedUser && <Question />}
      </Button>
      {open && buttonRef.current && (
        <Drop onClickOutside={() => setOpen(true)} onEsc={() => setOpen(false)} overflow="visible" target={buttonRef.current}>
          <Box>
            <ReactSelect
              theme={FlurishReactSelectTheme}
              value={selectedOption}
              styles={{ container: provided => ({ ...provided, minWidth: 250 }) }}
              options={options}
              menuIsOpen={true}
              isClearable={true}
              onChange={(option: ValueType<any>) => {
                if (option) {
                  if (isArrayOptionType(option)) {
                    throw new Error("can't select multiple users");
                  }
                  setOpen(false);
                  props.onChange && props.onChange(option.value);
                } else {
                  setOpen(false);
                  props.onChange && props.onChange(null);
                }
              }}
            />
          </Box>
        </Drop>
      )}
    </>
  );
};
