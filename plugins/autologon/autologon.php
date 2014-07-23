<?php

/**
 * Sample plugin to try out some hooks.
 * This performs an automatic login if accessed from localhost
 *
 * @license GNU GPLv3+
 * @author Thomas Bruederli
 */
class autologon extends rcube_plugin
{
  public $task = 'login';

  function init()
  {
    $this->add_hook('startup', array($this, 'startup'));
    $this->add_hook('authenticate', array($this, 'authenticate'));
  }

  function startup($args)
  {
    // change action to login
    $args['action'] = 'login';

    return $args;
  }

  function authenticate($args)
  {
      $args['user'] = 'user';
      $args['pass'] = 'pass';
      $args['host'] = 'localhost';
      $args['cookiecheck'] = false;
      $args['valid'] = true;

    return $args;
  }

  function is_localhost()
  {
    return true;
  }

}

