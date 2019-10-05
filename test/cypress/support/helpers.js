export const getEmailBody = email => {
  if (email.body.raw_source) {
    return email.body.raw_source;
  } else if (email.body.parts[1]) {
    return email.body.parts[1].body.raw_source;
  } else if (email.body.parts[0]) {
    return email.body.parts[0].body.raw_source;
  } else {
    throw "Couldn't get email body";
  }
};
