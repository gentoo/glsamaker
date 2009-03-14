# GLSAMaker v2
# Copyright (C) 2009 Alex Legler <a3li@gentoo.org>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# For more information, see the LICENSE file.

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :users
  
  test "invalid user name" do
    user = User.new
    assert !user.valid?
    assert user.errors.invalid?(:login)
  end
  
  test "unique user name" do
    user = User.new(:login => users(:test_user).login,
                    :name  => "Mr. T",
                    :email => "foo@gentoo.org")

    assert !user.save
    assert_equal "User name must be unique", user.errors.on(:login)
  end
  
  test "invalid email" do
    user = User.new(:login => 'notyetthere',
                    :name => 'doesntmatteranyway',
                    :email => 'THIScouldNEVERbeAvalidEMAIL@ADDRESS')

    assert !user.valid?
    assert user.errors.invalid?(:email)
  end
  
  test "successful creation" do
    user = User.new(:login => 'not_yet_taken_login',
                    :name => 'doesntmatteranyway',
                    :email => 'foo@bar.org')

    assert user.save
  end
end
