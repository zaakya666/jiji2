import React  from "react";
import Router from "react-router";
import MUI    from "material-ui";

const RaisedButton = MUI.RaisedButton;
const MenuItem     = MUI.MenuItem;
const Menu         = MUI.Menu;

export default class LeftNavi extends React.Component {

  constructor(props) {
    super(props);
    this.state = {};
  }

  render() {
    return (
      <Menu
        ref="leftNav"
        className="left-navi"
        zDepth={0}
        menuItems={this.navigator().menuItems()}
        selectedIndex={this.getSelectedIndex()}
        onItemClick={this.onLeftNavChange.bind(this)}
        onItemTap={this.onLeftNavChange.bind(this)}
      />
    );
  }

  getSelectedIndex() {
    const menuItems = this.navigator().menuItems();
    var current = null;
    for (let i = 0; i < menuItems.length; i++) {
      current = menuItems[i];
      if (!current.route) continue;
      if (this.router().isActive(current.route)) return i;
    }
  }

  onLeftNavChange(e, key, payload) {
    this.router().transitionTo(payload.route);
  }

  navigator() {
    return this.context.application.navigator;
  }
  router() {
    return this.context.router;
  }
}
LeftNavi.contextTypes = {
  application: React.PropTypes.object.isRequired,
  router: React.PropTypes.func
};