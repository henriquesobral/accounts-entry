AccountsEntry.entrySignUpHelpers = {
  showCompanyName: ->
    return AccountsEntry.settings.showCompanyNameField

  showName: ->
    fields = AccountsEntry.settings.passwordSignupFields

    _.contains([
      'NAME_AND_USERNAME_AND_EMAIL',
      'NAME_AND_USERNAME_AND_OPTIONAL_EMAIL',
      'NAME_AND_EMAIL',
      'NAME_AND_USERNAME'], fields)

  showEmail: ->
    fields = AccountsEntry.settings.passwordSignupFields

    _.contains([
      'NAME_AND_USERNAME_AND_EMAIL',
      'NAME_AND_USERNAME_AND_OPTIONAL_EMAIL',
      'NAME_AND_EMAIL'
      'USERNAME_AND_EMAIL',
      'USERNAME_AND_OPTIONAL_EMAIL',
      'EMAIL_ONLY'], fields)

  showUsername: ->
    fields = AccountsEntry.settings.passwordSignupFields

    _.contains([
      'NAME_AND_USERNAME_AND_EMAIL',
      'NAME_AND_USERNAME_AND_OPTIONAL_EMAIL',
      'NAME_AND_USERNAME',
      'USERNAME_AND_EMAIL',
      'USERNAME_AND_OPTIONAL_EMAIL',
      'USERNAME_ONLY'], fields)

  showSignupCode: ->
    AccountsEntry.settings.showSignupCode

  logo: ->
    AccountsEntry.settings.logo

  privacyUrl: ->
    AccountsEntry.settings.privacyUrl

  termsUrl: ->
    AccountsEntry.settings.termsUrl

  both: ->
    AccountsEntry.settings.privacyUrl &&
    AccountsEntry.settings.termsUrl

  neither: ->
    !AccountsEntry.settings.privacyUrl &&
    !AccountsEntry.settings.termsUrl

  emailIsOptional: ->
    fields = AccountsEntry.settings.passwordSignupFields

    _.contains(['USERNAME_AND_OPTIONAL_EMAIL'], fields)

  emailAddress: ->
    Session.get('email')
}

AccountsEntry.entrySignUpEvents = {
  'submit #signUp': (event, t) ->
    event.preventDefault()

    username =
      if t.find('input[name="username"]')
        t.find('input[name="username"]').value.toLowerCase()
      else
        undefined
    if username and AccountsEntry.settings.usernameToLower then username = username.toLowerCase()

    signupCode =
      if t.find('input[name="signupCode"]')
        t.find('input[name="signupCode"]').value
      else
        undefined

    name =
      if t.find('input[name="name"]')
        t.find('input[name="name"]').value
      else
        undefined

    companyName =
      if t.find('input[name="companyName"]')
        t.find('input[name="companyName"]').value
      else
        undefined

    trimInput = (val) ->
      val.replace /^\s*|\s*$/g, ""

    email =
      if t.find('input[type="email"]')
        trimInput t.find('input[type="email"]').value
      else
        undefined
    if AccountsEntry.settings.emailToLower and email then email = email.toLowerCase()

    password = t.find('input[type="password"]').value

    fields = AccountsEntry.settings.passwordSignupFields

    passwordErrors = do (password) ->
      errMsg = []
      msg = false
      if password.length < 7
        errMsg.push t9n("error.minChar")
      if password.search(/[a-z]/i) < 0
        errMsg.push t9n("error.pwOneLetter")
      if password.search(/[0-9]/) < 0
        errMsg.push t9n("error.pwOneDigit")

      if errMsg.length > 0
        msg = ""
        errMsg.forEach (e) ->
          msg = msg.concat "#{e}\r\n"

        Session.set 'entryError', msg
        return true

      return false

    if passwordErrors then return

    emailRequired = _.contains([
      'USERNAME_AND_EMAIL',
      'EMAIL_ONLY'], fields)

    usernameRequired = _.contains([
      'USERNAME_AND_EMAIL',
      'USERNAME_ONLY'], fields)

    nameRequired = fields.indexOf('NAME_') > -1 || fields.indexOf('_NAME') > -1

    companyNameRequired = AccountsEntry.settings.showCompanyNameField

    if nameRequired && name.length is 0
      Session.set('entryError', t9n("error.nameRequired"))
      return

    if companyNameRequired && companyName.length is 0
      Session.set('entryError', t9n("error.companyNameRequired"))
      return

    if usernameRequired && username.length is 0
      Session.set('entryError', t9n("error.usernameRequired"))
      return

    if username && AccountsEntry.isStringEmail(username)
      Session.set('entryError', t9n("error.usernameIsEmail"))
      return

    if emailRequired && email.length is 0
      Session.set('entryError', t9n("error.emailRequired"))
      return

    if AccountsEntry.settings.showSignupCode && signupCode.length is 0
      Session.set('entryError', t9n("error.signupCodeRequired"))
      return


    Meteor.call 'entryValidateSignupCode', signupCode, (err, valid) ->
      if valid
        profileData =
          name: name
          companyName: companyName
        newUserData =
          username: username
          email: email
          password: password
          profile: _.extend((AccountsEntry.settings.defaultProfile || {}), profileData)

        if Meteor.users.simpleSchema().namedContext().validate(newUserData, {modifier: false})
          Accounts.createUser newUserData, (err, data) ->
            if err
              T9NHelper.accountsError err
              return
            #login on client
            isEmailSignUp = _.contains([
              'USERNAME_AND_EMAIL',
              'EMAIL_ONLY'], AccountsEntry.settings.passwordSignupFields)
            userCredential = if isEmailSignUp then email else username
            Meteor.loginWithPassword userCredential, password, (error) ->
              if error
                T9NHelper.accountsError error
              else if Session.get 'fromWhere'
                Router.go Session.get('fromWhere')
                Session.set 'fromWhere', undefined
              else
                Router.go AccountsEntry.settings.dashboardRoute
        else
          console.log Meteor.users.simpleSchema().namedContext()
      else
        console.log err
        Session.set 'entryError', t9n("error.signupCodeIncorrect")
        return
}

Template.entrySignUp.helpers(AccountsEntry.entrySignUpHelpers)

Template.entrySignUp.events(AccountsEntry.entrySignUpEvents)
